import SwiftUI
import MapKit

// MARK: - Sections 7.9, 7.10, 7.11, 7.12: My Bookings List, Booking Details, Simplified Timeline, Quote Review/Approval, Repair Progress & Completion Confirmation

struct MyBookingsListView: View {
    @ObservedObject var store: TechCareStore
    @State private var selectedFilter: Int = 0 // 0 = Active, 1 = Completed/Cancelled
    
    var displayedBookings: [Booking] {
        if selectedFilter == 0 {
            return store.bookings.filter { !$0.status.isTerminal }
        } else {
            return store.bookings.filter { $0.status.isTerminal }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Booking Filter", selection: $selectedFilter) {
                    Text("Active (\(store.bookings.filter { !$0.status.isTerminal }.count))").tag(0)
                    Text("Closed / Past (\(store.bookings.filter { $0.status.isTerminal }.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                
                if displayedBookings.isEmpty {
                    ScrollView {
                        TCEmptyStateView(
                            icon: "calendar.badge.clock",
                            title: selectedFilter == 0 ? "No Active Doorstep Bookings" : "No Past Bookings",
                            message: "Book a doorstep repair from the Home tab to track technician arrival, quotation approval, and live repair progress.",
                            buttonTitle: "Go to Home"
                        ) {
                            store.selectedCustomerTab = 0
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(displayedBookings) { booking in
                                NavigationLink(destination: BookingDetailAndTrackingView(store: store, bookingId: booking.id)) {
                                    BookingListCard(store: store, booking: booking)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(18)
                    }
                }
            }
            .background(TCTheme.background)
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct BookingListCard: View {
    @ObservedObject var store: TechCareStore
    let booking: Booking
    
    var body: some View {
        let dev = store.device(for: booking.deviceId)
        let req = store.request(for: booking.repairRequestId)
        let tech = store.technician(for: booking.technicianId)
        let quote = store.latestQuote(for: booking.id)
        
        return TCCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(booking.bookingCode)
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    TCBadge(
                        text: booking.status.rawValue,
                        color: badgeColor(for: booking.status)
                    )
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TCTheme.tealSoft)
                            .frame(width: 48, height: 48)
                        Image(systemName: dev?.category.icon ?? "iphone")
                            .font(.title3)
                            .foregroundColor(TCTheme.teal)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(dev?.displayName ?? "Device")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.primary)
                        Text(req?.reportedIssue.rawValue ?? "Hardware Inspection")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(TCTheme.teal)
                        Text("\(booking.appointmentDate.formatted(date: .abbreviated, time: .omitted)) • \(booking.timeSlot)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Label(tech?.name ?? "Auto-Matching Specialist", systemImage: "person.badge.shield.checkmark.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let quote {
                        Text("Quote v\(quote.quoteVersion): \(INRFormatter.format(quote.totalAmountINR))")
                            .font(.caption.weight(.bold))
                            .foregroundColor(TCTheme.navy)
                    } else {
                        Text("Visit Fee: \(INRFormatter.format(booking.disclosedVisitFeeINR))")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func badgeColor(for status: BookingStatus) -> Color {
        switch status {
        case .quotePending, .awaitingCustomerConfirmation, .paymentPending:
            return TCTheme.warning
        case .paid, .completed, .quoteApproved:
            return TCTheme.success
        case .cancelled, .disputed:
            return TCTheme.danger
        default:
            return TCTheme.teal
        }
    }
}

// MARK: - Comprehensive Booking Detail, Simplified Timeline, Quote Review & Interactive Simulator

struct BookingDetailAndTrackingView: View {
    @ObservedObject var store: TechCareStore
    let bookingId: UUID
    
    @State private var clarificationText: String = ""
    @State private var showClarificationSheet: Bool = false
    @State private var showDisputeSheet: Bool = false
    @State private var disputeReasonText: String = ""
    @State private var showCancelConfirm: Bool = false
    @State private var showPaymentSheet: Bool = false
    @State private var showReviewSheet: Bool = false
    @State private var showSimulatedMap: Bool = false
    
    var booking: Booking? {
        store.bookings.first { $0.id == bookingId }
    }
    
    private let customerTimelineSteps: [(title: String, subtitle: String)] = [
        ("Booking Placed", "Request logged & privacy checklist confirmed"),
        ("Technician Visit", "Specialist assigned, en route & arrived at doorstep"),
        ("Diagnosis & Quote", "Device inspected & itemised quotation approved"),
        ("Repair & Testing", "Approved repair & 5-point quality check"),
        ("Confirmation & Pay", "Customer sign-off & invoice settlement"),
        ("Warranty Active", "180-day Repair Passport & GST invoice saved")
    ]
    
    var body: some View {
        Group {
            if let booking {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. Booking Status Header
                        statusHeaderCard(booking: booking)
                        
                        // 2. Interactive Prototype Simulator Controls (clearly labelled for College Lab Demo)
                        prototypeSimulatorBar(booking: booking)
                        
                        // 3. Action Card: Quotation Approval (Section 7.10)
                        if let latestQ = store.latestQuote(for: booking.id) {
                            quotationBreakdownCard(booking: booking, quote: latestQ)
                        }
                        
                        // 4. Action Card: Completion Confirmation (Section 7.12)
                        if booking.status == .awaitingCustomerConfirmation, let record = store.repairRecord(for: booking.id) {
                            completionConfirmationCard(booking: booking, record: record)
                        }
                        
                        // 5. Action Card: Payment & Invoice (Section 7.13)
                        if booking.status == .paymentPending || booking.status == .paid {
                            paymentAndInvoiceActionCard(booking: booking)
                        }
                        
                        // 6. Simplified Customer Timeline (Section 7.9)
                        simplifiedTimelineCard(booking: booking)
                        
                        // 7. Service Area & Demo Map Preview (Section 7.9: Clearly labelled as sample coordinates, never faking live GPS)
                        demoServiceAreaMapCard(booking: booking)
                        
                        // 8. Audit Log & Cancellation / Review Controls
                        auditAndFooterActions(booking: booking)
                    }
                    .padding(18)
                }
            } else {
                TCEmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Booking Not Found",
                    message: "This booking is no longer available."
                )
            }
        }
        .background(TCTheme.background)
        .navigationTitle(booking?.bookingCode ?? "Booking Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaymentSheet) {
            if let booking {
                PaymentSimulatorSheet(store: store, bookingId: booking.id)
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            if let booking {
                ReviewAndComplaintSheet(store: store, booking: booking)
            }
        }
        .sheet(isPresented: $showClarificationSheet) {
            if let booking, let quote = store.latestQuote(for: booking.id) {
                NavigationStack {
                    Form {
                        Section("Ask Technician for Clarification") {
                            TextField("e.g. Can we use standard OEM display or is waterproofing included?", text: $clarificationText, axis: .vertical)
                                .lineLimit(3...5)
                        }
                        Section {
                            Button("Send Question to Technician") {
                                store.respondToQuote(
                                    quoteId: quote.id,
                                    decision: .clarificationRequested,
                                    clarificationNote: clarificationText
                                )
                                showClarificationSheet = false
                            }
                            .fontWeight(.bold)
                            .foregroundColor(TCTheme.teal)
                        }
                    }
                    .navigationTitle("Request Clarification")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showClarificationSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showDisputeSheet) {
            if let booking {
                NavigationStack {
                    Form {
                        Section("Report Unresolved Issue / Hold Payment") {
                            TextField("Describe what is still not working properly...", text: $disputeReasonText, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        Section {
                            Button("Submit Dispute & Pause Payment", role: .destructive) {
                                let reason = disputeReasonText.isEmpty ? "Touch sensitivity still uneven on top edge" : disputeReasonText
                                store.customerRaiseDisputeOrIssue(bookingId: booking.id, issueReason: reason)
                                showDisputeSheet = false
                            }
                        }
                    }
                    .navigationTitle("Raise Repair Dispute")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showDisputeSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - 1. Status Header Card
    
    private func statusHeaderCard(booking: Booking) -> some View {
        let dev = store.device(for: booking.deviceId)
        let req = store.request(for: booking.repairRequestId)
        let tech = store.technician(for: booking.technicianId)
        
        return TCCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TCBadge(text: booking.status.rawValue.uppercased(), icon: "dot.radiowaves.left.and.right", color: TCTheme.teal)
                    Spacer()
                    TCBadge(text: booking.paymentStatus.rawValue, color: booking.paymentStatus == .paid ? TCTheme.success : TCTheme.navy)
                }
                
                Text("\(dev?.displayName ?? "Device") — \(req?.reportedIssue.rawValue ?? "Repair")")
                    .font(.headline.weight(.bold))
                
                Text(req?.symptomDescription ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Assigned Technician")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(tech?.name ?? "Matching Eligible Specialist...")
                            .font(.subheadline.weight(.bold))
                        if let tech {
                            Text(tech.verificationStatus.rawValue)
                                .font(.caption2)
                                .foregroundColor(TCTheme.teal)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Scheduled Slot")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(booking.timeSlot)
                            .font(.caption.weight(.bold))
                        Text("Visit Fee: \(INRFormatter.format(booking.disclosedVisitFeeINR))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - 2. Interactive Prototype Simulator Controls (for smooth College Lab Demo)
    
    private func prototypeSimulatorBar(booking: Booking) -> some View {
        TCCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "slider.horizontal.below.square.filled.and.square")
                        .foregroundColor(TCTheme.navy)
                    Text("Interactive Lab Demo Simulator")
                        .font(.caption.weight(.bold))
                        .foregroundColor(TCTheme.navy)
                    Spacer()
                    Button("Switch to Technician View") {
                        if let techId = booking.technicianId {
                            store.selectedTechnicianAccountId = techId
                        }
                        store.switchRole(to: .technician)
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundColor(TCTheme.teal)
                }
                
                Text("Simulate real-time doorstep workflow transitions or switch to the Technician Portal to submit quotes and test results:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if booking.status == .matchingTechnician {
                            simButton("1. Assign Technician") {
                                let tech = store.technicians.first!
                                store.technicianAcceptJob(bookingId: booking.id, technicianId: tech.id)
                            }
                        }
                        if booking.status == .technicianAssigned {
                            simButton("2. Tech On The Way") {
                                _ = store.advanceBookingStatus(
                                    bookingId: booking.id,
                                    to: .technicianOnTheWay,
                                    actor: "Simulator",
                                    note: "Technician dispatched to customer address."
                                )
                            }
                        }
                        if booking.status == .technicianOnTheWay {
                            simButton("3. Tech Arrived & Inspecting") {
                                _ = store.advanceBookingStatus(
                                    bookingId: booking.id,
                                    to: .diagnosisInProgress,
                                    actor: "Simulator",
                                    note: "Technician arrived at doorstep and started hardware diagnosis."
                                )
                            }
                        }
                        if booking.status == .diagnosisInProgress {
                            simButton("4. Generate Technician Quote") {
                                let samplePart = RepairPartItem(
                                    partName: "OEM Grade Replacement Module",
                                    partQuality: "Tested Original Grade",
                                    unitCostINR: 2400,
                                    quantity: 1,
                                    warrantyMonths: 6
                                )
                                _ = store.submitOrReviseQuote(
                                    bookingId: booking.id,
                                    diagnosis: "Hardware fault verified during doorstep inspection. Secondary board rails healthy.",
                                    recommendedRepair: "On-spot component replacement & calibration.",
                                    parts: [samplePart],
                                    labourINR: 450,
                                    waiveVisitFee: true,
                                    estimatedMinutes: 40,
                                    warrantyTerms: "180-Day TechCare Doorstep Warranty."
                                )
                            }
                        }
                        if booking.status == .quoteApproved {
                            simButton("5. Start Doorstep Repair") {
                                _ = store.advanceBookingStatus(
                                    bookingId: booking.id,
                                    to: .repairInProgress,
                                    actor: "Technician",
                                    note: "Customer approved quote. Started repair on ESD mat."
                                )
                            }
                        }
                        if booking.status == .repairInProgress || booking.status == .testing {
                            simButton("6. Finish Repair & 5-Point Tests") {
                                _ = store.technicianCompleteRepairAndTests(
                                    bookingId: booking.id,
                                    workPerformed: "Completed approved modular replacement and thermal/sensor calibration at customer's table.",
                                    testChecklist: FunctionalTestChecklist(),
                                    technicianNotes: "All 5 post-repair hardware checks passed in customer's presence."
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func simButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9))
                Text(label)
                    .font(.caption2.weight(.bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(TCTheme.navy)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
    }
    
    // MARK: - 3. Diagnosis & Quotation Approval Breakdown (Section 7.10 Core Feature)
    
    private func quotationBreakdownCard(booking: Booking, quote: RepairQuote) -> some View {
        let allVersions = store.quotes(for: booking.id)
        
        return TCCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TCBadge(
                        text: "QUOTATION v\(quote.quoteVersion) • \(quote.approvalStatus.rawValue.uppercased())",
                        icon: "doc.text.magnifyingglass",
                        color: quote.approvalStatus == .approved ? TCTheme.success : TCTheme.warning
                    )
                    Spacer()
                    Text("Est. \(quote.estimatedDurationMinutes) mins")
                        .font(.caption.weight(.bold))
                        .foregroundColor(TCTheme.teal)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Technician Diagnosis")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                    Text(quote.diagnosis)
                        .font(.subheadline)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended Repair")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                    Text(quote.recommendedRepair)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                if let revReason = quote.revisionExplanation, !revReason.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                            .foregroundColor(TCTheme.info)
                        Text("Revision Note (v\(quote.quoteVersion)): \(revReason)")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(TCTheme.info.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Divider()
                
                Text("Itemised Cost Breakdown (INR)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                
                ForEach(quote.parts) { part in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(part.partName)
                                .font(.caption.weight(.semibold))
                            Text("\(part.partQuality) • \(part.warrantyMonths) Months Warranty")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(INRFormatter.format(part.totalCostINR))
                            .font(.caption.weight(.bold))
                    }
                }
                
                HStack {
                    Text("Repair & Calibration Labour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(INRFormatter.format(quote.labourCostINR))
                        .font(.caption.weight(.semibold))
                }
                
                HStack {
                    Text("Doorstep Visit / Diagnostic Fee")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if quote.visitFeeWaivedOnApproval {
                        Text("\(INRFormatter.format(quote.visitOrDiagnosticFeeINR)) Waived")
                            .font(.caption.weight(.bold))
                            .foregroundColor(TCTheme.success)
                    } else {
                        Text(INRFormatter.format(quote.visitOrDiagnosticFeeINR))
                            .font(.caption.weight(.semibold))
                    }
                }
                
                HStack {
                    Text("Applicable GST (18%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(INRFormatter.format(quote.applicableTaxesINR))
                        .font(.caption.weight(.semibold))
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Payable After Completion")
                            .font(.subheadline.weight(.bold))
                        Text(quote.warrantyTerms)
                            .font(.caption2)
                            .foregroundColor(TCTheme.teal)
                    }
                    Spacer()
                    Text(INRFormatter.format(quote.totalAmountINR))
                        .font(.title3.weight(.bold))
                        .foregroundColor(TCTheme.navy)
                }
                
                // Customer Approval Buttons (Section 7.10)
                if quote.approvalStatus == .pending {
                    VStack(spacing: 10) {
                        Label("Protection Rule: Technician cannot mark repair as started or charge extra without your approval below.", systemImage: "lock.shield.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Button {
                            store.respondToQuote(quoteId: quote.id, decision: .approved)
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Approve Quotation (\(INRFormatter.format(quote.totalAmountINR))) & Authorise Repair")
                            }
                        }
                        .buttonStyle(TCPrimaryButtonStyle())
                        
                        HStack(spacing: 10) {
                            Button {
                                showClarificationSheet = true
                            } label: {
                                Label("Ask Clarification", systemImage: "questionmark.bubble.fill")
                            }
                            .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.deepBlue))
                            
                            Button {
                                store.respondToQuote(quoteId: quote.id, decision: .declined)
                            } label: {
                                Label("Decline (Pay \(INRFormatter.format(booking.disclosedVisitFeeINR)) Visit Fee)", systemImage: "xmark.circle.fill")
                            }
                            .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.danger))
                        }
                    }
                    .padding(.top, 6)
                }
                
                if allVersions.count > 1 {
                    Divider()
                    Text("Quote Version History (\(allVersions.count) versions recorded)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                    ForEach(allVersions) { qv in
                        HStack {
                            Text("v\(qv.quoteVersion) • \(INRFormatter.format(qv.totalAmountINR))")
                                .font(.caption2.monospaced())
                            Spacer()
                            Text(qv.approvalStatus.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 4. Completion Confirmation Card (Section 7.12)
    
    private func completionConfirmationCard(booking: Booking, record: RepairRecord) -> some View {
        TCCard {
            VStack(alignment: .leading, spacing: 12) {
                TCBadge(text: "REPAIR COMPLETE • AWAITING YOUR SIGN-OFF", icon: "checkmark.shield.fill", color: TCTheme.success)
                
                Text("Summary of Completed Work")
                    .font(.headline)
                Text(record.workPerformed)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("5-Point Functional Test Results:")
                        .font(.caption.weight(.bold))
                    testResultRow("Power & Boot Stability", passed: record.testResults.powerAndBootTestPassed)
                    testResultRow("Display, Touch & Brightness", passed: record.testResults.displayAndTouchTestPassed)
                    testResultRow("Charging Current & Battery Health", passed: record.testResults.chargingAndBatteryTestPassed)
                    testResultRow("Speakers, Mic & Cameras", passed: record.testResults.audioAndSensorsTestPassed)
                    testResultRow("Wi-Fi, Bluetooth & Cellular", passed: record.testResults.connectivityTestPassed)
                }
                .padding(10)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                HStack {
                    Text("Final Approved Amount:")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(INRFormatter.format(record.approvedQuoteAmountINR))
                        .font(.title3.weight(.bold))
                        .foregroundColor(TCTheme.teal)
                }
                
                Button {
                    store.customerConfirmRepairCompletion(bookingId: booking.id)
                    showPaymentSheet = true
                } label: {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Confirm Device Works Properly & Proceed to Payment")
                    }
                }
                .buttonStyle(TCPrimaryButtonStyle())
                
                Button {
                    showDisputeSheet = true
                } label: {
                    Label("Report Unresolved Issue / Hold Payment", systemImage: "exclamationmark.Bubble.fill")
                }
                .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.danger))
            }
        }
    }
    
    private func testResultRow(_ label: String, passed: Bool) -> some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(passed ? TCTheme.success : TCTheme.danger)
                .font(.caption)
            Text(label)
                .font(.caption)
            Spacer()
            Text(passed ? "PASSED" : "NEEDS CHECK")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(passed ? TCTheme.success : TCTheme.danger)
        }
    }
    
    // MARK: - 5. Payment & Invoice Card (Section 7.13)
    
    private func paymentAndInvoiceActionCard(booking: Booking) -> some View {
        let inv = store.invoice(for: booking.id)
        return TCCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TCBadge(
                        text: booking.paymentStatus == .paid ? "PAYMENT VERIFIED" : "PAYMENT DUE",
                        icon: "indianrupeesign.circle.fill",
                        color: booking.paymentStatus == .paid ? TCTheme.success : TCTheme.warning
                    )
                    Spacer()
                    if let inv {
                        Text(inv.invoiceNumber)
                            .font(.caption2.monospaced().weight(.bold))
                            .foregroundColor(.secondary)
                    }
                }
                
                if booking.paymentStatus != .paid {
                    Text("Your completion confirmation is recorded. Complete the simulated payment to generate your GST Invoice and activate your 180-Day Repair Passport.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showPaymentSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "indianrupeesign.circle.fill")
                            Text("Open Payment Simulator (UPI / Card / Cash Demo)")
                        }
                    }
                    .buttonStyle(TCPrimaryButtonStyle())
                } else if let inv {
                    NavigationLink(destination: InvoiceDetailView(invoice: inv)) {
                        HStack {
                            Image(systemName: "doc.richtext.fill")
                            Text("View Itemised GST Invoice (\(INRFormatter.format(inv.totalAmountINR)))")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(TCPrimaryButtonStyle(useTeal: true))
                    
                    Button {
                        showReviewSheet = true
                    } label: {
                        Label("Rate Technician & Write Review", systemImage: "star.bubble.fill")
                    }
                    .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.navy))
                }
            }
        }
    }
    
    // MARK: - 6. Simplified Customer Timeline (Section 7.9)
    
    private func simplifiedTimelineCard(booking: Booking) -> some View {
        let currentStep = booking.status.customerTimelineStep
        return TCCard {
            VStack(alignment: .leading, spacing: 12) {
                TCSectionHeader(
                    title: "Repair Status Timeline",
                    subtitle: "Current internal state: \(booking.status.rawValue)"
                )
                
                ForEach(0..<customerTimelineSteps.count, id: \.self) { index in
                    let step = customerTimelineSteps[index]
                    let isDone = currentStep > index || booking.status == .paid
                    let isCurrent = currentStep == index && booking.status != .paid
                    
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(isDone ? TCTheme.success : (isCurrent ? TCTheme.teal : Color.gray.opacity(0.25)))
                                    .frame(width: 24, height: 24)
                                Image(systemName: isDone ? "checkmark" : "\(index + 1).circle.fill")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.white)
                            }
                            if index < customerTimelineSteps.count - 1 {
                                Rectangle()
                                    .fill(isDone ? TCTheme.success : Color.gray.opacity(0.25))
                                    .frame(width: 2, height: 26)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.subheadline.weight(isCurrent || isDone ? .bold : .regular))
                                .foregroundColor(isCurrent ? TCTheme.teal : (isDone ? .primary : .secondary))
                            Text(step.subtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - 7. Clearly Labelled Demo Service Area Map (Section 7.9 rule: never fake real GPS)
    
    private func demoServiceAreaMapCard(booking: Booking) -> some View {
        let tech = store.technician(for: booking.technicianId)
        let coord = tech?.coordinate ?? CLLocationCoordinate2D(latitude: 28.5450, longitude: 77.3680)
        
        return TCCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TCBadge(text: "DEMO SERVICE AREA MAP (SIMULATED)", icon: "map.fill", color: TCTheme.deepBlue)
                    Spacer()
                    Button(showSimulatedMap ? "Hide Map" : "Show Area Map") {
                        withAnimation { showSimulatedMap.toggle() }
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(TCTheme.teal)
                }
                
                Text("Transparency Note: Live technician GPS tracking is only active when real CoreLocation permissions and server telemetry are enabled. Markers shown in demo mode represent static sample service zones.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if showSimulatedMap {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                    ))) {
                        Annotation("Service Zone (\(tech?.name ?? "TechCare"))", coordinate: coord) {
                            VStack(spacing: 2) {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(TCTheme.navy))
                                Text("Sample Zone")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemBackground))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - 8. Audit Log & Cancellation
    
    private func auditAndFooterActions(booking: Booking) -> some View {
        TCCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Auditable State History")
                    .font(.subheadline.weight(.bold))
                
                ForEach(booking.auditTrail.prefix(5)) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("\(entry.fromStatus.rawValue) → \(entry.toStatus.rawValue)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(TCTheme.teal)
                            Spacer()
                            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Text("\(entry.actor): \(entry.note)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
                
                if !booking.status.isTerminal && booking.status != .completed && booking.status != .paymentPending {
                    let cancelFee = BookingStateMachine.calculateCancellationFee(
                        for: booking.status,
                        disclosedVisitFee: booking.disclosedVisitFeeINR
                    )
                    Button(role: .destructive) {
                        showCancelConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "xmark.octagon.fill")
                            Text("Cancel Booking (Applicable Fee: \(INRFormatter.format(cancelFee)))")
                        }
                        .font(.caption.weight(.bold))
                    }
                    .alert("Cancel Booking \(booking.bookingCode)?", isPresented: $showCancelConfirm) {
                        Button("Keep Booking", role: .cancel) {}
                        Button("Confirm Cancel", role: .destructive) {
                            store.cancelBooking(bookingId: booking.id, reason: "Customer requested cancellation")
                        }
                    } message: {
                        Text("According to the disclosed cancellation policy for stage '\(booking.status.rawValue)', the cancellation charge is \(INRFormatter.format(cancelFee)).")
                    }
                }
            }
        }
    }
}
