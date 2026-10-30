import Foundation
import Combine
import SwiftUI

// MARK: - Section 13: Protocol-Based Service Abstractions
// Backend Strategy Choice: REST API + Webhook Backend Path (Option B)
// Why Option B (REST API Backend) was chosen as the primary production path:
// 1. Strict server-side state machine enforcement for quotations, revisions, and payment verification (Razorpay webhooks).
// 2. Auditable relational transactions (PostgreSQL) for INR financial ledgers, GST invoices, and commission splits.
// 3. No client-side exposure of payment secrets or administrative role overrides.

protocol AuthenticationServiceProtocol {
    func loginDemo(role: UserRole) -> User
}

protocol TechnicianServiceProtocol {
    func eligibleTechnicians(
        from all: [Technician],
        category: DeviceCategory,
        brand: String,
        issue: IssueCategory,
        area: String,
        slot: String,
        existingBookings: [Booking]
    ) -> [SmartTechnicianAllocator.ScoredTechnician]
}

protocol PaymentServiceProtocol {
    func simulatePaymentVerification(
        booking: Booking,
        approvedQuote: RepairQuote,
        method: PaymentMethod
    ) throws -> Payment
}

final class MockPaymentService: PaymentServiceProtocol {
    func simulatePaymentVerification(
        booking: Booking,
        approvedQuote: RepairQuote,
        method: PaymentMethod
    ) throws -> Payment {
        switch BookingStateMachine.validatePaymentAmount(
            requestedAmount: approvedQuote.totalAmountINR,
            approvedQuote: approvedQuote
        ) {
        case .success:
            let ref = "DEMO-RZP-\(Int.random(in: 100000...999999))"
            return Payment(
                bookingId: booking.id,
                amountINR: approvedQuote.totalAmountINR,
                paymentMethod: method,
                paymentStatus: .paid,
                gatewayReference: ref,
                createdAt: Date(),
                verifiedAt: Date()
            )
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Persistent Store Snapshot

struct TechCareStoreSnapshot: Codable {
    var currentUser: User
    var activeRole: UserRole
    var devices: [Device]
    var technicians: [Technician]
    var repairRequests: [RepairRequest]
    var bookings: [Booking]
    var quotes: [RepairQuote]
    var repairRecords: [RepairRecord]
    var payments: [Payment]
    var invoices: [Invoice]
    var reviews: [Review]
    var warrantyClaims: [WarrantyClaim]
    var complaints: [SupportComplaint]
    var platformCommissionPercent: Decimal
}

// MARK: - Central Observable Application Store

@MainActor
final class TechCareStore: ObservableObject {
    //Onboarding & Navigation State
    @Published var hasCompletedOnboarding: Bool = false
    @Published var isAuthenticated: Bool = true
    @Published var activeRole: UserRole = .customer
    @Published var selectedCustomerTab: Int = 0
    @Published var selectedTechnicianTab: Int = 0
    
    // Domain Collections
    @Published var currentUser: User
    @Published var devices: [Device]
    @Published var technicians: [Technician]
    @Published var repairRequests: [RepairRequest]
    @Published var bookings: [Booking]
    @Published var quotes: [RepairQuote]
    @Published var repairRecords: [RepairRecord]
    @Published var payments: [Payment]
    @Published var invoices: [Invoice]
    @Published var reviews: [Review]
    @Published var warrantyClaims: [WarrantyClaim]
    @Published var complaints: [SupportComplaint]
    
    // Configurable Business Model Settings (Section 10)
    @Published var platformCommissionPercent: Decimal = 12
    @Published var selectedTechnicianAccountId: UUID
    
    // Draft Booking Flow State (Customer)
    @Published var draftCategory: DeviceCategory = .mobilePhone
    @Published var draftBrand: String = "Apple"
    @Published var draftModel: String = "iPhone 15 Pro Max"
    @Published var draftSerialHint: String = "4829"
    @Published var draftWarrantyStatus: WarrantyStatus = .expired
    @Published var draftIssue: IssueCategory = .brokenDisplay
    @Published var draftSymptomDescription: String = "Screen glass cracked on bottom right corner after an accidental drop; touch flickers intermittently."
    @Published var draftPowersOn: Bool = true
    @Published var draftHistoryNotes: String = "No prior third-party repairs. Original display."
    @Published var draftPhotoLabels: [String] = []
    @Published var draftAppointmentDate: Date = Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
    @Published var draftTimeSlot: String = "02:00 PM - 04:00 PM"
    @Published var draftSelectedAddress: SavedAddress
    @Published var draftSpecialInstructions: String = "Please call at the society main gate for entry pass."
    @Published var draftPrivacyChecklist: PrivacySafetyChecklist = PrivacySafetyChecklist(
        dataBackedUp: true,
        sensitiveAppsLockedOrRemoved: true,
        maintenanceModeEnabledIfSupported: false,
        physicalConditionRecorded: true,
        consentsToDiagnosticInspection: true,
        unlockPasscodePolicyUnderstood: true
    )
    @Published var draftSelectedTechnician: Technician? = nil
    
    // Notification Banner Toast
    @Published var activeBannerMessage: String? = nil
    
    private let paymentService: PaymentServiceProtocol = MockPaymentService()
    private let persistenceURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return docs.appendingPathComponent("techcare_demo_state_v1.json")
    }()
    
    init() {
        let seed = Self.makeRealisticSeedData()
        self.currentUser = seed.currentUser
        self.activeRole = seed.activeRole
        self.devices = seed.devices
        self.technicians = seed.technicians
        self.repairRequests = seed.repairRequests
        self.bookings = seed.bookings
        self.quotes = seed.quotes
        self.repairRecords = seed.repairRecords
        self.payments = seed.payments
        self.invoices = seed.invoices
        self.reviews = seed.reviews
        self.warrantyClaims = seed.warrantyClaims
        self.complaints = seed.complaints
        self.platformCommissionPercent = seed.platformCommissionPercent
        self.selectedTechnicianAccountId = seed.technicians.first?.id ?? UUID()
        self.draftSelectedAddress = seed.currentUser.savedAddresses.first ?? SavedAddress(
            label: "Home",
            line1: "Flat 402, Tower B, Lotus Boulevard",
            area: "Sector 100",
            city: "Noida, UP",
            pincode: "201304",
            landmark: "Near Pathways School"
        )
        self.draftSelectedTechnician = seed.technicians.first
        
        loadPersistedStateIfAvailable()
    }
    
    // MARK: - Persistence
    
    func saveState() {
        let snapshot = TechCareStoreSnapshot(
            currentUser: currentUser,
            activeRole: activeRole,
            devices: devices,
            technicians: technicians,
            repairRequests: repairRequests,
            bookings: bookings,
            quotes: quotes,
            repairRecords: repairRecords,
            payments: payments,
            invoices: invoices,
            reviews: reviews,
            warrantyClaims: warrantyClaims,
            complaints: complaints,
            platformCommissionPercent: platformCommissionPercent
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: persistenceURL, options: .atomic)
        }
    }
    
    func loadPersistedStateIfAvailable() {
        guard let data = try? Data(contentsOf: persistenceURL),
              let decoded = try? JSONDecoder().decode(TechCareStoreSnapshot.self, from: data) else {
            return
        }
        self.currentUser = decoded.currentUser
        self.activeRole = decoded.activeRole
        self.devices = decoded.devices
        self.technicians = decoded.technicians
        self.repairRequests = decoded.repairRequests
        self.bookings = decoded.bookings
        self.quotes = decoded.quotes
        self.repairRecords = decoded.repairRecords
        self.payments = decoded.payments
        self.invoices = decoded.invoices
        self.reviews = decoded.reviews
        self.warrantyClaims = decoded.warrantyClaims
        self.complaints = decoded.complaints
        self.platformCommissionPercent = decoded.platformCommissionPercent
    }
    
    func resetToFreshDemoData() {
        try? FileManager.default.removeItem(at: persistenceURL)
        let seed = Self.makeRealisticSeedData()
        self.currentUser = seed.currentUser
        self.activeRole = .customer
        self.devices = seed.devices
        self.technicians = seed.technicians
        self.repairRequests = seed.repairRequests
        self.bookings = seed.bookings
        self.quotes = seed.quotes
        self.repairRecords = seed.repairRecords
        self.payments = seed.payments
        self.invoices = seed.invoices
        self.reviews = seed.reviews
        self.warrantyClaims = seed.warrantyClaims
        self.complaints = seed.complaints
        self.platformCommissionPercent = seed.platformCommissionPercent
        self.selectedTechnicianAccountId = seed.technicians.first?.id ?? UUID()
        showToast("Demo data reset to fresh default state.")
    }
    
    func showToast(_ message: String) {
        withAnimation {
            activeBannerMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [weak self] in
            if self?.activeBannerMessage == message {
                withAnimation {
                    self?.activeBannerMessage = nil
                }
            }
        }
    }
    
    // MARK: - Role & Account Helpers
    
    var activeTechnicianProfile: Technician {
        get {
            technicians.first(where: { $0.id == selectedTechnicianAccountId }) ?? technicians[0]
        }
        set {
            if let idx = technicians.firstIndex(where: { $0.id == newValue.id }) {
                technicians[idx] = newValue
                saveState()
            }
        }
    }
    
    func switchRole(to role: UserRole) {
        withAnimation(.easeInOut(duration: 0.2)) {
            activeRole = role
            currentUser.role = role
        }
        saveState()
        showToast("Switched demo view to \(role.rawValue)")
    }
    
    // MARK: - Query Helpers
    
    func device(for id: UUID) -> Device? {
        devices.first { $0.id == id }
    }
    
    func request(for id: UUID) -> RepairRequest? {
        repairRequests.first { $0.id == id }
    }
    
    func technician(for id: UUID?) -> Technician? {
        guard let id else { return nil }
        return technicians.first { $0.id == id }
    }
    
    func quotes(for bookingId: UUID) -> [RepairQuote] {
        quotes
            .filter { $0.bookingId == bookingId }
            .sorted { $0.quoteVersion > $1.quoteVersion }
    }
    
    func latestQuote(for bookingId: UUID) -> RepairQuote? {
        quotes(for: bookingId).first
    }
    
    func invoice(for bookingId: UUID) -> Invoice? {
        invoices.first { $0.bookingId == bookingId }
    }
    
    func repairRecord(for bookingId: UUID) -> RepairRecord? {
        repairRecords.first { $0.bookingId == bookingId }
    }
    
    func reviews(for technicianId: UUID) -> [Review] {
        reviews.filter { $0.technicianId == technicianId }.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Customer Booking Creation (Section 7.8 & 14)
    
    func createBookingFromDraft(chosenTechnician: Technician?) -> Result<Booking, TechCareBusinessError> {
        let trimmedDesc = draftSymptomDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDesc.isEmpty {
            return .failure(.missingRequiredFields("Problem description"))
        }
        if !draftPrivacyChecklist.isMinimumSafetyConfirmed {
            return .failure(.privacyChecklistIncomplete)
        }
        if draftAppointmentDate < Date().addingTimeInterval(-3600) {
            return .failure(.invalidAppointmentDate)
        }
        
        // Check technician conflict if a specific technician was chosen
        if let tech = chosenTechnician {
            let hasConflict = bookings.contains { b in
                b.technicianId == tech.id &&
                Calendar.current.isDate(b.appointmentDate, inSameDayAs: draftAppointmentDate) &&
                b.timeSlot == draftTimeSlot &&
                !b.status.isTerminal
            }
            if hasConflict {
                return .failure(.technicianScheduleConflict)
            }
        }
        
        // Create or reuse device
        let device: Device
        if let existing = devices.first(where: {
            $0.category == draftCategory &&
            $0.brand.caseInsensitiveCompare(draftBrand) == .orderedSame &&
            $0.model.caseInsensitiveCompare(draftModel) == .orderedSame
        }) {
            device = existing
        } else {
            let newDevice = Device(
                ownerId: currentUser.id,
                category: draftCategory,
                brand: draftBrand,
                model: draftModel,
                serialOrIMEIHint: draftSerialHint.isEmpty ? "8821" : draftSerialHint,
                warrantyStatus: draftWarrantyStatus
            )
            devices.insert(newDevice, at: 0)
            device = newDevice
        }
        
        // Determine technician via SmartTechnicianAllocator if not explicitly picked
        let assignedTech: Technician? = chosenTechnician ?? SmartTechnicianAllocator.rankTechnicians(
            candidates: technicians,
            category: draftCategory,
            brand: draftBrand,
            issue: draftIssue,
            preferredArea: draftSelectedAddress.area,
            appointmentSlot: draftTimeSlot,
            existingBookings: bookings
        ).first?.technician
        
        let initialStatus: BookingStatus = assignedTech != nil ? .technicianAssigned : .matchingTechnician
        let request = RepairRequest(
            customerId: currentUser.id,
            deviceId: device.id,
            reportedIssue: draftIssue,
            symptomDescription: trimmedDesc,
            powersOn: draftPowersOn,
            deviceHistoryNotes: draftHistoryNotes,
            photoReferences: draftPhotoLabels,
            requestedDate: draftAppointmentDate,
            preferredTimeSlot: draftTimeSlot,
            serviceAddress: draftSelectedAddress,
            currentStatus: initialStatus,
            assignedTechnicianId: assignedTech?.id,
            privacyChecklist: draftPrivacyChecklist
        )
        repairRequests.insert(request, at: 0)
        
        let visitFee = assignedTech?.visitDiagnosticFeeINR ?? Decimal(299)
        let code = "TC-2026-\(Int.random(in: 1000...9999))"
        let audit = StateTransitionAuditEntry(
            fromStatus: .draft,
            toStatus: initialStatus,
            actor: currentUser.name,
            note: assignedTech != nil
                ? "Booking created and assigned to \(assignedTech!.name)."
                : "Booking requested; matching eligible technician."
        )
        
        let booking = Booking(
            bookingCode: code,
            repairRequestId: request.id,
            customerId: currentUser.id,
            deviceId: device.id,
            technicianId: assignedTech?.id,
            appointmentDate: draftAppointmentDate,
            timeSlot: draftTimeSlot,
            status: initialStatus,
            paymentStatus: .notDue,
            disclosedVisitFeeINR: visitFee,
            specialInstructions: draftSpecialInstructions,
            requiresPickupWorkshop: draftIssue == .hardwareDiagnosis,
            auditTrail: [audit]
        )
        bookings.insert(booking, at: 0)
        saveState()
        showToast("Booking \(code) confirmed!")
        return .success(booking)
    }
    
    // MARK: - Smart Technician Acceptance / Reassignment (Section 8.3 & 8.4)
    
    func technicianAcceptJob(bookingId: UUID, technicianId: UUID) {
        guard let idx = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        let oldStatus = bookings[idx].status
        bookings[idx].technicianId = technicianId
        bookings[idx].status = .technicianAssigned
        let techName = technician(for: technicianId)?.name ?? "Technician"
        bookings[idx].auditTrail.insert(
            StateTransitionAuditEntry(
                fromStatus: oldStatus,
                toStatus: .technicianAssigned,
                actor: techName,
                note: "Technician accepted doorstep appointment."
            ),
            at: 0
        )
        syncRequestStatus(for: bookings[idx])
        saveState()
        showToast("Job accepted by \(techName).")
    }
    
    func technicianDeclineOrTimeoutJob(bookingId: UUID, decliningTechnicianId: UUID, reason: String = "Declined / Response Timeout") {
        guard let idx = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        var booking = bookings[idx]
        if !booking.declinedTechnicianIds.contains(decliningTechnicianId) {
            booking.declinedTechnicianIds.append(decliningTechnicianId)
        }
        
        let req = request(for: booking.repairRequestId)
        let dev = device(for: booking.deviceId)
        let ranked = SmartTechnicianAllocator.rankTechnicians(
            candidates: technicians,
            category: dev?.category ?? .mobilePhone,
            brand: dev?.brand ?? "Apple",
            issue: req?.reportedIssue ?? .brokenDisplay,
            preferredArea: req?.serviceAddress.area ?? "Noida",
            appointmentSlot: booking.timeSlot,
            existingBookings: bookings,
            excludedTechnicianIds: booking.declinedTechnicianIds
        )
        
        let oldStatus = booking.status
        if let nextBest = ranked.first?.technician {
            booking.technicianId = nextBest.id
            booking.status = .technicianAssigned
            booking.disclosedVisitFeeINR = nextBest.visitDiagnosticFeeINR
            booking.auditTrail.insert(
                StateTransitionAuditEntry(
                    fromStatus: oldStatus,
                    toStatus: .technicianAssigned,
                    actor: "Smart Allocator",
                    note: "\(reason). Automatically reassigned to next eligible specialist: \(nextBest.name)."
                ),
                at: 0
            )
            showToast("Reassigned to \(nextBest.name)")
        } else {
            booking.technicianId = nil
            booking.status = .matchingTechnician
            booking.requiresPickupWorkshop = true
            booking.auditTrail.insert(
                StateTransitionAuditEntry(
                    fromStatus: oldStatus,
                    toStatus: .matchingTechnician,
                    actor: "Smart Allocator",
                    note: "No other doorstep specialist available in slot. Offered reschedule or safe Workshop Pickup & Drop-off."
                ),
                at: 0
            )
            showToast("Offered Workshop Pickup / Alternative Slot.")
        }
        
        bookings[idx] = booking
        syncRequestStatus(for: booking)
        saveState()
    }
    
    // MARK: - Quotation Submission, Revision & Customer Approval (Section 7.10 & 8.5)
    
    func submitOrReviseQuote(
        bookingId: UUID,
        diagnosis: String,
        recommendedRepair: String,
        parts: [RepairPartItem],
        labourINR: Decimal,
        waiveVisitFee: Bool,
        estimatedMinutes: Int,
        warrantyTerms: String,
        revisionExplanation: String? = nil
    ) -> RepairQuote? {
        guard let bIdx = bookings.firstIndex(where: { $0.id == bookingId }) else { return nil }
        let existingQuotes = quotes(for: bookingId)
        
        // Supersede previous quotes
        for q in existingQuotes {
            if let qIdx = quotes.firstIndex(where: { $0.id == q.id }) {
                quotes[qIdx].approvalStatus = .superseded
            }
        }
        
        let nextVersion = (existingQuotes.first?.quoteVersion ?? 0) + 1
        let visitFee = bookings[bIdx].disclosedVisitFeeINR
        let totals = RepairQuote.calculateTotal(
            parts: parts,
            labour: labourINR,
            visitFee: visitFee,
            waiveVisitFee: waiveVisitFee
        )
        
        let newQuote = RepairQuote(
            bookingId: bookingId,
            diagnosis: diagnosis,
            recommendedRepair: recommendedRepair,
            parts: parts,
            partsCostINR: totals.partsTotal,
            labourCostINR: labourINR,
            applicableTaxesINR: totals.taxAmount,
            visitOrDiagnosticFeeINR: visitFee,
            visitFeeWaivedOnApproval: waiveVisitFee,
            totalAmountINR: totals.grandTotal,
            estimatedDurationMinutes: estimatedMinutes,
            warrantyTerms: warrantyTerms,
            quoteVersion: nextVersion,
            revisionExplanation: revisionExplanation,
            approvalStatus: .pending
        )
        quotes.insert(newQuote, at: 0)
        
        let oldStatus = bookings[bIdx].status
        bookings[bIdx].status = .quotePending
        bookings[bIdx].auditTrail.insert(
            StateTransitionAuditEntry(
                fromStatus: oldStatus,
                toStatus: .quotePending,
                actor: technician(for: bookings[bIdx].technicianId)?.name ?? "Technician",
                note: "Submitted Quotation v\(nextVersion) for \(INRFormatter.format(totals.grandTotal)). Awaiting customer approval."
            ),
            at: 0
        )
        syncRequestStatus(for: bookings[bIdx])
        saveState()
        showToast("Quotation v\(nextVersion) sent to customer for approval.")
        return newQuote
    }
    
    func respondToQuote(quoteId: UUID, decision: QuoteApprovalStatus, clarificationNote: String? = nil) {
        guard let qIdx = quotes.firstIndex(where: { $0.id == quoteId }) else { return }
        let bookingId = quotes[qIdx].bookingId
        guard let bIdx = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        
        quotes[qIdx].approvalStatus = decision
        if let clarificationNote, !clarificationNote.isEmpty {
            quotes[qIdx].customerClarificationNote = clarificationNote
        }
        let oldStatus = bookings[bIdx].status
        
        switch decision {
        case .approved:
            quotes[qIdx].approvalTimestamp = Date()
            bookings[bIdx].status = .quoteApproved
            bookings[bIdx].auditTrail.insert(
                StateTransitionAuditEntry(
                    fromStatus: oldStatus,
                    toStatus: .quoteApproved,
                    actor: currentUser.name,
                    note: "Customer approved Quotation v\(quotes[qIdx].quoteVersion) (\(INRFormatter.format(quotes[qIdx].totalAmountINR))). Technician authorised to start repair."
                ),
                at: 0
            )
            showToast("Quotation approved! Technician may now start repair.")
            
        case .declined:
            // Customer declined repair quote; only disclosed visit/diagnostic fee applies
            bookings[bIdx].status = .paymentPending
            bookings[bIdx].paymentStatus = .pending
            bookings[bIdx].auditTrail.insert(
                StateTransitionAuditEntry(
                    fromStatus: oldStatus,
                    toStatus: .paymentPending,
                    actor: currentUser.name,
                    note: "Customer declined repair quote. Only disclosed diagnostic visit fee (\(INRFormatter.format(bookings[bIdx].disclosedVisitFeeINR))) applies."
                ),
                at: 0
            )
            showToast("Quotation declined. Only diagnostic visit fee applies.")
            
        case .clarificationRequested:
            bookings[bIdx].status = .diagnosisInProgress
            bookings[bIdx].auditTrail.insert(
                StateTransitionAuditEntry(
                    fromStatus: oldStatus,
                    toStatus: .diagnosisInProgress,
                    actor: currentUser.name,
                    note: "Customer requested clarification: \(clarificationNote ?? "Please explain part options")"
                ),
                at: 0
            )
            showToast("Clarification request sent to technician.")
            
        default:
            break
        }
        
        syncRequestStatus(for: bookings[bIdx])
        saveState()
    }
    
    // MARK: - Booking Status Transitions & Enforcement (Section 7.9, 7.11, 7.12, 8.6, 14)
    
    func advanceBookingStatus(bookingId: UUID, to nextStatus: BookingStatus, actor: String, note: String) -> Result<Void, TechCareBusinessError> {
        guard let bIdx = bookings.firstIndex(where: { $0.id == bookingId }) else {
            return .failure(.noTechnicianAssigned)
        }
        let booking = bookings[bIdx]
        let latestQ = latestQuote(for: bookingId)
        
        let validation = BookingStateMachine.canTransition(
            from: booking.status,
            to: nextStatus,
            hasAssignedTechnician: booking.technicianId != nil,
            requiresPickupWorkshop: booking.requiresPickupWorkshop,
            latestQuoteStatus: latestQ?.approvalStatus
        )
        
        if case .failure(let error) = validation {
            showToast(error.localizedDescription)
            return .failure(error)
        }
        
        let oldStatus = bookings[bIdx].status
        bookings[bIdx].status = nextStatus
        bookings[bIdx].auditTrail.insert(
            StateTransitionAuditEntry(
                fromStatus: oldStatus,
                toStatus: nextStatus,
                actor: actor,
                note: note
            ),
            at: 0
        )
        syncRequestStatus(for: bookings[bIdx])
        saveState()
        return .success(())
    }
    
    func technicianCompleteRepairAndTests(
        bookingId: UUID,
        workPerformed: String,
        testChecklist: FunctionalTestChecklist,
        technicianNotes: String
    ) -> Result<Void, TechCareBusinessError> {
        guard let bIdx = bookings.firstIndex(where: { $0.id == bookingId }) else {
            return .failure(.noTechnicianAssigned)
        }
        let booking = bookings[bIdx]
        guard let approvedQuote = latestQuote(for: bookingId), approvedQuote.approvalStatus == .approved else {
            return .failure(.quoteNotApprovedYet)
        }
        
        let tech = technician(for: booking.technicianId)
        let req = request(for: booking.repairRequestId)
        
        let record = RepairRecord(
            bookingId: booking.id,
            deviceId: booking.deviceId,
            technicianId: booking.technicianId ?? UUID(),
            technicianName: tech?.name ?? "Assigned Technician",
            customerReportedIssue: req?.reportedIssue.rawValue ?? "Hardware Repair",
            diagnosis: approvedQuote.diagnosis,
            workPerformed: workPerformed,
            partsReplaced: approvedQuote.parts,
            approvedQuoteAmountINR: approvedQuote.totalAmountINR,
            testResults: testChecklist,
            completionTimestamp: Date(),
            technicianNotes: technicianNotes,
            warrantyExpiryDate: Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date(),
            warrantyTerms: approvedQuote.warrantyTerms
        )
        
        repairRecords.removeAll { $0.bookingId == booking.id }
        repairRecords.insert(record, at: 0)
        
        // Link record to device repair passport
        if let dIdx = devices.firstIndex(where: { $0.id == booking.deviceId }) {
            if !devices[dIdx].repairHistoryIds.contains(record.id) {
                devices[dIdx].repairHistoryIds.insert(record.id, at: 0)
            }
            devices[dIdx].warrantyStatus = .techCareWarranty
        }
        
        // Rule 5: Technician cannot trigger payment directly; moves to awaitingCustomerConfirmation
        let oldStatus = bookings[bIdx].status
        bookings[bIdx].status = .awaitingCustomerConfirmation
        bookings[bIdx].auditTrail.insert(
            StateTransitionAuditEntry(
                fromStatus: oldStatus,
                toStatus: .awaitingCustomerConfirmation,
                actor: tech?.name ?? "Technician",
                note: "Repair & 5-point functional tests completed. Awaiting customer sign-off."
            ),
            at: 0
        )
        syncRequestStatus(for: bookings[bIdx])
        saveState()
        showToast("Repair logged! Waiting for customer confirmation.")
        return .success(())
    }
    
    func customerConfirmRepairCompletion(bookingId: UUID) {
        guard let bIdx = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        let oldStatus = bookings[bIdx].status
        bookings[bIdx].status = .paymentPending
        bookings[bIdx].paymentStatus = .pending
        bookings[bIdx].auditTrail.insert(
            StateTransitionAuditEntry(
                fromStatus: oldStatus,
                toStatus: .paymentPending,
                actor: currentUser.name,
                note: "Customer inspected device and confirmed repair completion. Invoice ready for payment."
            ),
            at: 0
        )
        syncRequestStatus(for: bookings[bIdx])
        saveState()
        showToast("Completion confirmed! Ready for payment.")
    }
    
    func customerRaiseDisputeOrIssue(bookingId: UUID, issueReason: String) {
        guard let bIdx = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        let oldStatus = bookings[bIdx].status
        bookings[bIdx].status = .disputed
        bookings[bIdx].disputeReason = issueReason
        bookings[bIdx].auditTrail.insert(
            StateTransitionAuditEntry(
                fromStatus: oldStatus,
                toStatus: .disputed,
                actor: currentUser.name,
                note: "Customer reported unresolved issue: \(issueReason). Payment held pending resolution."
            ),
            at: 0
        )
        complaints.insert(
            SupportComplaint(
                bookingCode: bookings[bIdx].bookingCode,
                customerName: currentUser.name,
                category: "Post-Repair Quality Dispute",
                description: issueReason,
                status: "Open"
            ),
            at: 0
        )
        syncRequestStatus(for: bookings[bIdx])
        saveState()
        showToast("Dispute logged. Payment paused & support notified.")
    }
    
    func cancelBooking(bookingId: UUID, reason: String) {
        guard let bIdx = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        let current = bookings[bIdx].status
        let fee = BookingStateMachine.calculateCancellationFee(
            for: current,
            disclosedVisitFee: bookings[bIdx].disclosedVisitFeeINR
        )
        bookings[bIdx].cancellationInfo = CancellationRecord(
            cancelledByRole: activeRole,
            reason: reason,
            cancellationFeeINR: fee
        )
        bookings[bIdx].status = .cancelled
        bookings[bIdx].auditTrail.insert(
            StateTransitionAuditEntry(
                fromStatus: current,
                toStatus: .cancelled,
                actor: activeRole.rawValue,
                note: "Cancelled (\(reason)). Applicable cancellation fee: \(INRFormatter.format(fee))."
            ),
            at: 0
        )
        syncRequestStatus(for: bookings[bIdx])
        saveState()
        showToast("Booking cancelled.")
    }
    
    // MARK: - Simulated Payment & Invoice Generation (Section 7.13)
    
    func processSimulatedPayment(bookingId: UUID, method: PaymentMethod) -> Result<Invoice, TechCareBusinessError> {
        guard let bIdx = bookings.firstIndex(where: { $0.id == bookingId }) else {
            return .failure(.noTechnicianAssigned)
        }
        let booking = bookings[bIdx]
        if booking.paymentStatus == .paid {
            return .failure(.paymentAlreadyProcessed)
        }
        
        // Determine payable quote or diagnostic fee if quote was declined
        let quote = latestQuote(for: bookingId)
        let dev = device(for: booking.deviceId)
        let tech = technician(for: booking.technicianId)
        
        var lineItems: [InvoiceLineItem] = []
        var subtotal: Decimal = 0
        var tax: Decimal = 0
        var grandTotal: Decimal = 0
        
        if let quote, quote.approvalStatus == .approved {
            do {
                let payment = try paymentService.simulatePaymentVerification(
                    booking: booking,
                    approvedQuote: quote,
                    method: method
                )
                payments.insert(payment, at: 0)
            } catch let err as TechCareBusinessError {
                return .failure(err)
            } catch {
                return .failure(.quoteNotApprovedYet)
            }
            
            for part in quote.parts {
                lineItems.append(
                    InvoiceLineItem(
                        title: part.partName,
                        subtitle: "\(part.partQuality) • \(part.warrantyMonths)m Warranty",
                        amountINR: part.totalCostINR
                    )
                )
            }
            lineItems.append(
                InvoiceLineItem(
                    title: "Doorstep Repair & Calibration Labour",
                    subtitle: quote.recommendedRepair,
                    amountINR: quote.labourCostINR
                )
            )
            if !quote.visitFeeWaivedOnApproval && quote.visitOrDiagnosticFeeINR > 0 {
                lineItems.append(
                    InvoiceLineItem(
                        title: "Home Visit & Diagnostic Fee",
                        subtitle: "Standard doorstep inspection",
                        amountINR: quote.visitOrDiagnosticFeeINR
                    )
                )
            }
            subtotal = quote.partsCostINR + quote.labourCostINR + (quote.visitFeeWaivedOnApproval ? 0 : quote.visitOrDiagnosticFeeINR)
            tax = quote.applicableTaxesINR
            grandTotal = quote.totalAmountINR
        } else {
            // Diagnostic visit fee only (when quote was declined)
            let visitFee = booking.disclosedVisitFeeINR
            let payment = Payment(
                bookingId: booking.id,
                amountINR: visitFee,
                paymentMethod: method,
                paymentStatus: .paid,
                gatewayReference: "DEMO-RZP-VISIT-\(Int.random(in: 10000...99999))",
                createdAt: Date(),
                verifiedAt: Date()
            )
            payments.insert(payment, at: 0)
            lineItems.append(
                InvoiceLineItem(
                    title: "Doorstep Inspection & Diagnostic Visit Fee",
                    subtitle: "Quotation declined; only disclosed visit fee charged",
                    amountINR: visitFee
                )
            )
            subtotal = visitFee
            tax = 0
            grandTotal = visitFee
        }
        
        let invoice = Invoice(
            bookingId: booking.id,
            invoiceNumber: "INV-\(booking.bookingCode)",
            customerName: currentUser.name,
            technicianName: tech?.name ?? "TechCare Specialist",
            deviceSummary: dev?.displayName ?? "Electronic Device",
            itemisedCharges: lineItems,
            subtotalINR: subtotal,
            taxAmountINR: tax,
            discountINR: 0,
            totalAmountINR: grandTotal,
            paymentMethod: method
        )
        invoices.removeAll { $0.bookingId == booking.id }
        invoices.insert(invoice, at: 0)
        
        if let rIdx = repairRecords.firstIndex(where: { $0.bookingId == booking.id }) {
            repairRecords[rIdx].invoiceId = invoice.id
        }
        
        let oldStatus = bookings[bIdx].status
        bookings[bIdx].paymentStatus = .paid
        bookings[bIdx].status = .paid
        bookings[bIdx].auditTrail.insert(
            StateTransitionAuditEntry(
                fromStatus: oldStatus,
                toStatus: .paid,
                actor: "Payment Verifier (Demo)",
                note: "Verified \(INRFormatter.format(grandTotal)) via \(method.rawValue). Invoice \(invoice.invoiceNumber) issued."
            ),
            at: 0
        )
        syncRequestStatus(for: bookings[bIdx])
        saveState()
        showToast("Payment verified! Invoice \(invoice.invoiceNumber) generated.")
        return .success(invoice)
    }
    
    // MARK: - Reviews & Warranty Claims (Section 7.14 & 7.15)
    
    func submitReview(bookingId: UUID, rating: Int, comment: String) -> Result<Review, TechCareBusinessError> {
        guard let booking = bookings.first(where: { $0.id == bookingId }) else {
            return .failure(.reviewNotAllowedBeforeCompletion)
        }
        if case .failure(let err) = BookingStateMachine.canSubmitReview(for: booking.status) {
            return .failure(err)
        }
        let dev = device(for: booking.deviceId)
        let review = Review(
            bookingId: booking.id,
            customerId: currentUser.id,
            customerName: currentUser.name,
            technicianId: booking.technicianId ?? technicians[0].id,
            rating: max(1, min(5, rating)),
            comment: comment,
            deviceSummary: dev?.displayName ?? "Device Repair"
        )
        reviews.insert(review, at: 0)
        saveState()
        showToast("Thank you! Your review has been published.")
        return .success(review)
    }
    
    func submitWarrantyClaim(repairRecordId: UUID, issueDescription: String) -> Result<WarrantyClaim, TechCareBusinessError> {
        guard let record = repairRecords.first(where: { $0.id == repairRecordId }) else {
            return .failure(.warrantyExpiredOrInvalid)
        }
        if record.warrantyExpiryDate < Date() {
            return .failure(.warrantyExpiredOrInvalid)
        }
        let claim = WarrantyClaim(
            repairRecordId: record.id,
            bookingId: record.bookingId,
            customerId: currentUser.id,
            issueDescription: issueDescription,
            status: .scheduledRevisit,
            resolutionNotes: "Warranty verified active until \(record.warrantyExpiryDate.formatted(date: .abbreviated, time: .omitted)). Priority free technician revisit queued."
        )
        warrantyClaims.insert(claim, at: 0)
        if let rIdx = repairRecords.firstIndex(where: { $0.id == repairRecordId }) {
            repairRecords[rIdx].followUpOrComplaintIds.append(claim.id)
        }
        saveState()
        showToast("Warranty claim registered! Free revisit scheduled.")
        return .success(claim)
    }
    
    // MARK: - Technician Earnings Calculation (Section 8.7 & 10)
    
    func earningsBreakdowns(for technicianId: UUID) -> [TechnicianEarningBreakdown] {
        let techBookings = bookings.filter {
            $0.technicianId == technicianId &&
            ($0.status == .paid || $0.status == .completed || $0.status == .paymentPending)
        }
        return techBookings.map { booking in
            let gross = latestQuote(for: booking.id)?.totalAmountINR ?? booking.disclosedVisitFeeINR
            let comm = ((gross * platformCommissionPercent) / Decimal(100)).roundedINR()
            let tds = ((gross * Decimal(1)) / Decimal(100)).roundedINR() // 1% Sec 194O TDS illustrative
            let net = gross - comm - tds
            let status = booking.paymentStatus == .paid ? "Settled to Bank" : "Pending Customer Payment"
            return TechnicianEarningBreakdown(
                bookingCode: booking.bookingCode,
                completedDate: booking.appointmentDate,
                grossRepairAmountINR: gross,
                platformCommissionRatePercent: platformCommissionPercent,
                platformCommissionINR: comm,
                taxDeductionINR: tds,
                netPayoutINR: net,
                payoutStatus: status
            )
        }
    }
    
    private func syncRequestStatus(for booking: Booking) {
        if let rIdx = repairRequests.firstIndex(where: { $0.id == booking.repairRequestId }) {
            repairRequests[rIdx].currentStatus = booking.status
            repairRequests[rIdx].assignedTechnicianId = booking.technicianId
        }
    }
}
