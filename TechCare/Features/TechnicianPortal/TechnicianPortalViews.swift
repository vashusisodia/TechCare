import SwiftUI

// MARK: - Section 8: Technician Experience (Dashboard, Job Requests, Active Jobs, Quote Creation, Completion & Earnings)

struct TechnicianDashboardTabView: View {
    @ObservedObject var store: TechCareStore
    
    var tech: Technician {
        store.activeTechnicianProfile
    }
    
    var incomingRequests: [Booking] {
        store.bookings.filter {
            $0.status == .matchingTechnician || ($0.technicianId == tech.id && $0.status == .requested)
        }
    }
    
    var activeJobs: [Booking] {
        store.bookings.filter {
            $0.technicianId == tech.id &&
            !$0.status.isTerminal &&
            $0.status != .matchingTechnician
        }
    }
    
    var earningsList: [TechnicianEarningBreakdown] {
        store.earningsBreakdowns(for: tech.id)
    }
    
    var netTotalINR: Decimal {
        earningsList.reduce(Decimal(0)) { $0 + $1.netPayoutINR }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Technician Selector & Online Availability Toggle
                    TCCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(TCTheme.heroGradient)
                                        .frame(width: 52, height: 52)
                                    Text(tech.initials)
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Menu {
                                        ForEach(store.technicians) { item in
                                            Button(item.name) {
                                                store.selectedTechnicianAccountId = item.id
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(tech.name)
                                                .font(.headline.weight(.bold))
                                                .foregroundColor(.primary)
                                            Image(systemName: "chevron.down.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(TCTheme.teal)
                                        }
                                    }
                                    Text(tech.verificationStatus.rawValue)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(TCTheme.teal)
                                    Text(tech.serviceArea)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { tech.isAvailableOnline },
                                    set: { newVal in
                                        var updated = tech
                                        updated.isAvailableOnline = newVal
                                        store.activeTechnicianProfile = updated
                                        store.showToast(newVal ? "You are now ONLINE for doorstep requests." : "You are now OFFLINE.")
                                    }
                                ))
                                .labelsHidden()
                                .tint(TCTheme.success)
                            }
                            
                            HStack {
                                TCBadge(
                                    text: tech.isAvailableOnline ? "ONLINE • RECEIVING REQUESTS" : "OFFLINE",
                                    icon: "dot.radiowaves.left.and.right",
                                    color: tech.isAvailableOnline ? TCTheme.success : .secondary
                                )
                                Spacer()
                                Button("Switch to Customer View") {
                                    store.switchRole(to: .customer)
                                }
                                .font(.caption2.weight(.bold))
                                .foregroundColor(TCTheme.teal)
                            }
                        }
                    }
                    
                    // KPI Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        techStatCard(title: "Incoming Requests", value: "\(incomingRequests.count)", icon: "bell.badge.fill", color: TCTheme.warning) {
                            store.selectedTechnicianTab = 1
                        }
                        techStatCard(title: "Active Doorstep Jobs", value: "\(activeJobs.count)", icon: "wrench.and.screwdriver.fill", color: TCTheme.teal) {
                            store.selectedTechnicianTab = 2
                        }
                        techStatCard(title: "Net Earnings (INR)", value: INRFormatter.format(netTotalINR), icon: "indianrupeesign.circle.fill", color: TCTheme.success) {
                            store.selectedTechnicianTab = 3
                        }
                        techStatCard(title: "Rating & Jobs", value: "\(String(format: "%.1f★", tech.rating)) (\(tech.completedJobs))", icon: "star.fill", color: TCTheme.navy) {
                            store.selectedTechnicianTab = 4
                        }
                    }
                    
                    // Priority Active Job Quick Card
                    if let firstActive = activeJobs.first {
                        VStack(alignment: .leading, spacing: 10) {
                            TCSectionHeader(title: "Current Assigned Doorstep Job", subtitle: "Tap to diagnose, submit quote, or record tests")
                            NavigationLink(destination: TechnicianActiveJobWorkspaceView(store: store, bookingId: firstActive.id)) {
                                BookingListCard(store: store, booking: firstActive)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Incoming Requests Preview
                    if !incomingRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            TCSectionHeader(title: "New Incoming Requests", subtitle: "Accept or decline before response deadline")
                            ForEach(incomingRequests) { booking in
                                TechnicianIncomingRequestCard(store: store, booking: booking)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("Technician Hub")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func techStatCard(title: String, value: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            TCCard {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    Text(value)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.primary)
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section 8.3: Technician Incoming Job Requests & Simulated Timeout Reassignment

struct TechnicianJobRequestsTabView: View {
    @ObservedObject var store: TechCareStore
    
    var incomingBookings: [Booking] {
        store.bookings.filter {
            $0.status == .matchingTechnician || $0.status == .requested
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if incomingBookings.isEmpty {
                        TCEmptyStateView(
                            icon: "tray.and.arrow.down.fill",
                            title: "No Pending Job Requests",
                            message: "All doorstep requests have been accepted or assigned. Check Active Jobs to manage ongoing repairs.",
                            buttonTitle: "View Active Jobs"
                        ) {
                            store.selectedTechnicianTab = 2
                        }
                    } else {
                        ForEach(incomingBookings) { booking in
                            TechnicianIncomingRequestCard(store: store, booking: booking)
                        }
                    }
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("Job Requests")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TechnicianIncomingRequestCard: View {
    @ObservedObject var store: TechCareStore
    let booking: Booking
    
    var body: some View {
        let dev = store.device(for: booking.deviceId)
        let req = store.request(for: booking.repairRequestId)
        let tech = store.activeTechnicianProfile
        
        return TCCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TCBadge(text: "RESPONSE WINDOW: 10 MINS (SIMULATED)", icon: "timer", color: TCTheme.warning)
                    Spacer()
                    Text(booking.bookingCode)
                        .font(.caption2.monospaced().weight(.bold))
                }
                
                Text("\(dev?.displayName ?? "Device") • \(req?.reportedIssue.rawValue ?? "Issue")")
                    .font(.headline)
                
                Text(req?.symptomDescription ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(req?.serviceAddress.area ?? "Noida", systemImage: "mappin.and.ellipse")
                        .font(.caption)
                    Spacer()
                    Label(booking.timeSlot, systemImage: "clock.fill")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                HStack {
                    Text("Disclosed Diagnostic Visit Fee:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(INRFormatter.format(booking.disclosedVisitFeeINR))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(TCTheme.teal)
                }
                
                HStack(spacing: 10) {
                    Button {
                        store.technicianAcceptJob(bookingId: booking.id, technicianId: tech.id)
                        store.selectedTechnicianTab = 2
                    } label: {
                        Label("Accept Doorstep Job", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(TCPrimaryButtonStyle(useTeal: true))
                    
                    Button {
                        store.technicianDeclineOrTimeoutJob(
                            bookingId: booking.id,
                            decliningTechnicianId: tech.id,
                            reason: "Declined / Simulated Timeout by \(tech.name)"
                        )
                    } label: {
                        Label("Decline / Timeout", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.danger))
                }
            }
        }
    }
}

// MARK: - Section 8.5 & 8.6: Technician Active Jobs, Quote Submission & Completion Workspace

struct TechnicianActiveJobsTabView: View {
    @ObservedObject var store: TechCareStore
    
    var activeBookings: [Booking] {
        store.bookings.filter { !$0.status.isTerminal }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if activeBookings.isEmpty {
                        TCEmptyStateView(
                            icon: "wrench.adjustable",
                            title: "No Active Doorstep Jobs",
                            message: "Accept an incoming job request or create a new customer booking to manage it here."
                        )
                    } else {
                        ForEach(activeBookings) { booking in
                            NavigationLink(destination: TechnicianActiveJobWorkspaceView(store: store, bookingId: booking.id)) {
                                BookingListCard(store: store, booking: booking)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("Active Jobs")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TechnicianActiveJobWorkspaceView: View {
    @ObservedObject var store: TechCareStore
    let bookingId: UUID
    
    // Quote Builder State
    @State private var diagnosisText: String = "Inspected device on ESD mat. Primary module fault confirmed; motherboard power rails healthy."
    @State private var recommendedRepairText: String = "Modular OEM-grade component replacement & sensor calibration."
    @State private var partName: String = "OEM Grade Replacement Module"
    @State private var partQuality: String = "Original Pulled / Tested Grade"
    @State private var partCostString: String = "3200"
    @State private var partWarrantyMonths: Int = 6
    @State private var labourCostString: String = "500"
    @State private var waiveVisitFee: Bool = true
    @State private var durationMinutes: Int = 45
    @State private var warrantyTerms: String = "180-Day TechCare Doorstep Warranty on replaced component."
    @State private var revisionExplanation: String = ""
    
    // Completion Builder State
    @State private var workPerformedNotes: String = "Replaced approved part on anti-static mat, cleaned internal connectors, and calibrated sensors."
    @State private var technicianCompletionNotes: String = "Tested in front of customer. No personal data accessed."
    @State private var testChecklist = FunctionalTestChecklist()
    @State private var ruleViolationBanner: String? = nil
    
    var booking: Booking? {
        store.bookings.first { $0.id == bookingId }
    }
    
    var latestQuote: RepairQuote? {
        store.latestQuote(for: bookingId)
    }
    
    var body: some View {
        Group {
            if let booking {
                let dev = store.device(for: booking.deviceId)
                let req = store.request(for: booking.repairRequestId)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Job Status Overview
                        TCCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    TCBadge(text: booking.status.rawValue.uppercased(), color: TCTheme.teal)
                                    Spacer()
                                    Text(booking.bookingCode)
                                        .font(.caption.monospaced().weight(.bold))
                                }
                                Text("\(dev?.displayName ?? "Device") • \(req?.reportedIssue.rawValue ?? "Issue")")
                                    .font(.headline)
                                Text("Customer Address: \(req?.serviceAddress.fullFormatted ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let clarification = latestQuote?.customerClarificationNote, !clarification.isEmpty {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                                            .foregroundColor(TCTheme.warning)
                                        Text("Customer Clarification Request: \"\(clarification)\"")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(10)
                                    .background(TCTheme.warning.opacity(0.14))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        
                        // Step 1: Travel & Arrival Controls
                        TCCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Step 1: Travel & Doorstep Inspection")
                                    .font(.subheadline.weight(.bold))
                                
                                HStack(spacing: 10) {
                                    Button("Mark En Route") {
                                        _ = store.advanceBookingStatus(
                                            bookingId: booking.id,
                                            to: .technicianOnTheWay,
                                            actor: store.activeTechnicianProfile.name,
                                            note: "Technician en route to customer address."
                                        )
                                    }
                                    .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.deepBlue))
                                    
                                    Button("Arrived & Start Diagnosis") {
                                        _ = store.advanceBookingStatus(
                                            bookingId: booking.id,
                                            to: .diagnosisInProgress,
                                            actor: store.activeTechnicianProfile.name,
                                            note: "Arrived at doorstep and started hardware diagnosis."
                                        )
                                    }
                                    .buttonStyle(TCPrimaryButtonStyle(useTeal: true))
                                }
                            }
                        }
                        
                        // Step 2: Diagnosis & Quotation Submission / Revision (Section 8.5)
                        TCCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(latestQuote == nil ? "Step 2: Submit Repair Quotation" : "Step 2: Revise Quotation (Current: v\(latestQuote!.quoteVersion))")
                                        .font(.subheadline.weight(.bold))
                                    Spacer()
                                    if let latestQuote {
                                        TCBadge(text: latestQuote.approvalStatus.rawValue, color: latestQuote.approvalStatus == .approved ? TCTheme.success : TCTheme.warning)
                                    }
                                }
                                
                                TCFormField(label: "Hardware Diagnosis", required: true) {
                                    TextField("Diagnosis details", text: $diagnosisText, axis: .vertical)
                                        .lineLimit(2...4)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                TCFormField(label: "Part Name & Specification", required: true) {
                                    TextField("Part name", text: $partName)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                HStack(spacing: 12) {
                                    TCFormField(label: "Part Cost (₹)", required: true) {
                                        TextField("e.g. 3200", text: $partCostString)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    TCFormField(label: "Labour Cost (₹)", required: true) {
                                        TextField("e.g. 500", text: $labourCostString)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                
                                Toggle("Waive Visit Fee (\(INRFormatter.format(booking.disclosedVisitFeeINR))) Upon Quote Approval", isOn: $waiveVisitFee)
                                    .font(.caption.weight(.semibold))
                                    .tint(TCTheme.teal)
                                
                                if latestQuote != nil {
                                    TCFormField(label: "Reason for Revised Quote (Mandatory if discovering extra issue)", required: true) {
                                        TextField("Explain why the quote is being revised...", text: $revisionExplanation)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                
                                Button {
                                    let pCost = Decimal(string: partCostString) ?? 2500
                                    let lCost = Decimal(string: labourCostString) ?? 500
                                    let part = RepairPartItem(
                                        partName: partName,
                                        partQuality: partQuality,
                                        unitCostINR: pCost,
                                        quantity: 1,
                                        warrantyMonths: partWarrantyMonths
                                    )
                                    _ = store.submitOrReviseQuote(
                                        bookingId: booking.id,
                                        diagnosis: diagnosisText,
                                        recommendedRepair: recommendedRepairText,
                                        parts: [part],
                                        labourINR: lCost,
                                        waiveVisitFee: waiveVisitFee,
                                        estimatedMinutes: durationMinutes,
                                        warrantyTerms: warrantyTerms,
                                        revisionExplanation: revisionExplanation.isEmpty ? nil : revisionExplanation
                                    )
                                } label: {
                                    HStack {
                                        Image(systemName: "paperplane.fill")
                                        Text(latestQuote == nil ? "Submit Quotation to Customer" : "Submit Revised Quotation (Requires Fresh Approval)")
                                    }
                                }
                                .buttonStyle(TCPrimaryButtonStyle())
                            }
                        }
                        
                        // Step 3: Start Repair & Complete 5-Point Tests (Section 8.5 & 8.6 — Enforces Quote Approval First!)
                        TCCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Step 3: Perform Repair & Functional Tests")
                                        .font(.subheadline.weight(.bold))
                                    Spacer()
                                    if latestQuote?.approvalStatus != .approved {
                                        TCBadge(text: "LOCKED UNTIL CUSTOMER APPROVES QUOTE", icon: "lock.fill", color: TCTheme.danger)
                                    } else {
                                        TCBadge(text: "QUOTE APPROVED • UNLOCKED", icon: "lock.open.fill", color: TCTheme.success)
                                    }
                                }
                                
                                Text("Business Rule Enforcement: Attempting to start repair before customer quote approval will be blocked by the state machine.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if let ruleViolationBanner {
                                    Label(ruleViolationBanner, systemImage: "xmark.shield.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(TCTheme.danger)
                                        .padding(8)
                                        .background(TCTheme.danger.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Button {
                                    switch store.advanceBookingStatus(
                                        bookingId: booking.id,
                                        to: .repairInProgress,
                                        actor: store.activeTechnicianProfile.name,
                                        note: "Started doorstep repair."
                                    ) {
                                    case .success:
                                        ruleViolationBanner = nil
                                    case .failure(let err):
                                        ruleViolationBanner = err.localizedDescription
                                    }
                                } label: {
                                    Label("Mark Repair Work Started", systemImage: "wrench.and.screwdriver.fill")
                                }
                                .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.teal))
                                
                                Divider()
                                
                                Text("5-Point Post-Repair Hardware Checklist")
                                    .font(.caption.weight(.bold))
                                
                                Toggle("1. Power & Boot Stability Passed", isOn: $testChecklist.powerAndBootTestPassed)
                                    .font(.caption)
                                Toggle("2. Display, Touch & Brightness Passed", isOn: $testChecklist.displayAndTouchTestPassed)
                                    .font(.caption)
                                Toggle("3. Charging Current & Battery Passed", isOn: $testChecklist.chargingAndBatteryTestPassed)
                                    .font(.caption)
                                Toggle("4. Audio, Mic & Camera Sensors Passed", isOn: $testChecklist.audioAndSensorsTestPassed)
                                    .font(.caption)
                                Toggle("5. Wi-Fi, Bluetooth & Cellular Passed", isOn: $testChecklist.connectivityTestPassed)
                                    .font(.caption)
                                
                                TCFormField(label: "Completion Summary & Notes") {
                                    TextField("Work performed notes", text: $workPerformedNotes, axis: .vertical)
                                        .lineLimit(2...4)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                Button {
                                    switch store.technicianCompleteRepairAndTests(
                                        bookingId: booking.id,
                                        workPerformed: workPerformedNotes,
                                        testChecklist: testChecklist,
                                        technicianNotes: technicianCompletionNotes
                                    ) {
                                    case .success:
                                        ruleViolationBanner = nil
                                    case .failure(let err):
                                        ruleViolationBanner = err.localizedDescription
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                        Text("Log Completed Repair & Request Customer Confirmation")
                                    }
                                }
                                .buttonStyle(TCPrimaryButtonStyle())
                            }
                        }
                    }
                    .padding(18)
                }
            } else {
                TCEmptyStateView(icon: "wrench", title: "Job Not Found", message: "Please select an active job.")
            }
        }
        .background(TCTheme.background)
        .navigationTitle("Technician Job Workspace")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section 8.7 & 10: Technician Earnings & Commission Transparency

struct TechnicianEarningsTabView: View {
    @ObservedObject var store: TechCareStore
    
    var tech: Technician {
        store.activeTechnicianProfile
    }
    
    var breakdowns: [TechnicianEarningBreakdown] {
        store.earningsBreakdowns(for: tech.id)
    }
    
    var grossSum: Decimal {
        breakdowns.reduce(0) { $0 + $1.grossRepairAmountINR }
    }
    
    var commissionSum: Decimal {
        breakdowns.reduce(0) { $0 + $1.platformCommissionINR }
    }
    
    var netSum: Decimal {
        breakdowns.reduce(0) { $0 + $1.netPayoutINR }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Summary Hero
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: TCTheme.Radius.xl)
                            .fill(TCTheme.heroGradient)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            TCBadge(text: "DEMO EARNINGS LEDGER • \(tech.subscriptionTier.uppercased())", icon: "indianrupeesign.circle.fill", color: .white)
                            Text(INRFormatter.format(netSum))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Net Technician Take-Home (After \(NSDecimalNumber(decimal: store.platformCommissionPercent))% Platform Commission & 1% TDS)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                            
                            Divider().background(Color.white.opacity(0.3))
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Gross Repair Value")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.75))
                                    Text(INRFormatter.format(grossSum))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Platform Commission (\(NSDecimalNumber(decimal: store.platformCommissionPercent))%)")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.75))
                                    Text(INRFormatter.format(commissionSum))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(20)
                    }
                    
                    // Section 10 Business Model Illustration Card
                    TCCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Transparent Platform Commission Policy", systemImage: "percent")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(TCTheme.navy)
                            Text("Example: On a ₹2,000 approved repair with a 12% platform commission, ₹240 goes toward platform matching, insurance, and support before payment gateway and operating costs, while the technician retains the remaining ₹1,760 (less statutory TDS).")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Job-by-Job Payouts
                    TCSectionHeader(title: "Job-wise Payout Breakdown", subtitle: "Distinguishes settled payouts from pending customer payments")
                    
                    ForEach(breakdowns) { item in
                        TCCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.bookingCode)
                                        .font(.caption.monospaced().weight(.bold))
                                    Spacer()
                                    TCBadge(
                                        text: item.payoutStatus,
                                        color: item.payoutStatus.contains("Settled") ? TCTheme.success : TCTheme.warning
                                    )
                                }
                                HStack {
                                    Text("Gross Approved Billing")
                                    Spacer()
                                    Text(INRFormatter.format(item.grossRepairAmountINR))
                                }
                                .font(.caption)
                                
                                HStack {
                                    Text("TechCare Commission (\(NSDecimalNumber(decimal: item.platformCommissionRatePercent))%)")
                                    Spacer()
                                    Text("- \(INRFormatter.format(item.platformCommissionINR))")
                                        .foregroundColor(TCTheme.danger)
                                }
                                .font(.caption)
                                
                                HStack {
                                    Text("Statutory TDS (1%)")
                                    Spacer()
                                    Text("- \(INRFormatter.format(item.taxDeductionINR))")
                                        .foregroundColor(.secondary)
                                }
                                .font(.caption)
                                
                                Divider()
                                
                                HStack {
                                    Text("Net Technician Payout")
                                        .font(.subheadline.weight(.bold))
                                    Spacer()
                                    Text(INRFormatter.format(item.netPayoutINR))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(TCTheme.teal)
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("Earnings & Payouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
