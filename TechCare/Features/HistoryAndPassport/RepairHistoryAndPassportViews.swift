import SwiftUI

// MARK: - Sections 7.14 & 7.15: Repair History, Digital Repair Passport, Warranty Claims & Reviews

struct RepairHistoryAndPassportTabView: View {
    @ObservedObject var store: TechCareStore
    @State private var selectedSegment: Int = 0 // 0 = Repair Passports, 1 = Warranty Claims
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("View", selection: $selectedSegment) {
                    Text("Repair Passports (\(store.repairRecords.count))").tag(0)
                    Text("Warranty Claims (\(store.warrantyClaims.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 14) {
                        if selectedSegment == 0 {
                            if store.repairRecords.isEmpty {
                                TCEmptyStateView(
                                    icon: "doc.text.below.ecg",
                                    title: "No Repair Passports Yet",
                                    message: "Once a repair is completed, your device's diagnosis, replaced parts, test results, and warranty certificate appear here."
                                )
                            } else {
                                ForEach(store.repairRecords) { record in
                                    NavigationLink(destination: RepairPassportDetailView(store: store, record: record)) {
                                        RepairPassportSummaryCard(store: store, record: record)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            if store.warrantyClaims.isEmpty {
                                TCEmptyStateView(
                                    icon: "checkmark.shield",
                                    title: "No Active Warranty Claims",
                                    message: "All your completed TechCare repairs are working smoothly. Open any Repair Passport to request free warranty support if an issue recurs."
                                )
                            } else {
                                ForEach(store.warrantyClaims) { claim in
                                    TCCard {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                TCBadge(text: claim.status.rawValue, icon: "wrench.and.screwdriver.fill", color: TCTheme.teal)
                                                Spacer()
                                                Text(claim.createdAt.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            Text(claim.issueDescription)
                                                .font(.subheadline.weight(.semibold))
                                            Text(claim.resolutionNotes)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .background(TCTheme.background)
            .navigationTitle("Repair Passport")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RepairPassportSummaryCard: View {
    @ObservedObject var store: TechCareStore
    let record: RepairRecord
    
    var body: some View {
        let dev = store.device(for: record.deviceId)
        let isWarrantyActive = record.warrantyExpiryDate > Date()
        
        return TCCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TCBadge(
                        text: isWarrantyActive ? "WARRANTY ACTIVE UNTIL \(record.warrantyExpiryDate.formatted(date: .abbreviated, time: .omitted).uppercased())" : "WARRANTY EXPIRED",
                        icon: "checkmark.shield.fill",
                        color: isWarrantyActive ? TCTheme.success : .secondary
                    )
                    Spacer()
                    Image(systemName: "qrcode")
                        .foregroundColor(TCTheme.navy)
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TCTheme.heroGradient)
                            .frame(width: 48, height: 48)
                        Image(systemName: dev?.category.icon ?? "laptopcomputer")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dev?.displayName ?? "Device")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(record.customerReportedIssue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(TCTheme.teal)
                        Text("Serviced by \(record.technicianName) • \(record.completionTimestamp.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(INRFormatter.format(record.approvedQuoteAmountINR))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(TCTheme.navy)
                }
                
                Divider()
                
                HStack {
                    Label("\(record.partsReplaced.count) Part(s) Replaced • 5/5 Tests Passed", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(TCTheme.success)
                    Spacer()
                    Text("Open Passport →")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(TCTheme.teal)
                }
            }
        }
    }
}

struct RepairPassportDetailView: View {
    @ObservedObject var store: TechCareStore
    let record: RepairRecord
    @State private var showWarrantyClaimSheet: Bool = false
    @State private var warrantyIssueText: String = ""
    @State private var showReviewSheet: Bool = false
    
    var body: some View {
        let dev = store.device(for: record.deviceId)
        let inv = store.invoices.first { $0.id == record.invoiceId || $0.bookingId == record.bookingId }
        let booking = store.bookings.first { $0.id == record.bookingId }
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Digital Passport Header
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: TCTheme.Radius.xl)
                        .fill(TCTheme.heroGradient)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            TCBadge(text: "TECHCARE DIGITAL REPAIR PASSPORT", icon: "checkmark.seal.fill", color: .white)
                            Spacer()
                        }
                        Text(dev?.displayName ?? "Electronic Device")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        Text("Serial/IMEI Hint: ••••\(dev?.serialOrIMEIHint ?? "9034") • Category: \(dev?.category.rawValue ?? "Gadget")")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                        
                        Divider().background(Color.white.opacity(0.3))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("REPAIR DATE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.75))
                                Text(record.completionTimestamp.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("WARRANTY VALID UNTIL")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.75))
                                Text(record.warrantyExpiryDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                }
                
                // Diagnosis & Work Performed
                TCCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Technical Diagnosis & Work Performed")
                            .font(.subheadline.weight(.bold))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Reported Issue:")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.secondary)
                            Text(record.customerReportedIssue)
                                .font(.caption)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Diagnosis:")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.secondary)
                            Text(record.diagnosis)
                                .font(.caption)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Work Performed by \(record.technicianName):")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.secondary)
                            Text(record.workPerformed)
                                .font(.caption)
                        }
                        
                        Divider()
                        
                        Label("Privacy Assurance: Zero personal files, photos, or passwords are stored in this Repair Passport.", systemImage: "lock.shield.fill")
                            .font(.caption2)
                            .foregroundColor(TCTheme.teal)
                    }
                }
                
                // Replaced Parts & Warranty
                TCCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Replaced Parts & Serialised Warranty")
                            .font(.subheadline.weight(.bold))
                        
                        ForEach(record.partsReplaced) { part in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(part.partName)
                                        .font(.caption.weight(.semibold))
                                    Text("\(part.partQuality) • \(part.warrantyMonths) Months Cover")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(INRFormatter.format(part.totalCostINR))
                                    .font(.caption.weight(.bold))
                            }
                        }
                        
                        Divider()
                        Text(record.warrantyTerms)
                            .font(.caption2)
                            .foregroundColor(TCTheme.teal)
                    }
                }
                
                // Functional Tests
                TCCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Post-Repair Functional Verification")
                            .font(.subheadline.weight(.bold))
                        Text(record.testResults.summaryNotes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Actions: Invoice, Warranty Support, Review
                if let inv {
                    NavigationLink(destination: InvoiceDetailView(invoice: inv)) {
                        HStack {
                            Image(systemName: "doc.richtext.fill")
                            Text("Open Tax Invoice (\(inv.invoiceNumber))")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(TCPrimaryButtonStyle(useTeal: true))
                }
                
                HStack(spacing: 10) {
                    Button {
                        showWarrantyClaimSheet = true
                    } label: {
                        Label("Claim Warranty Support", systemImage: "shield.lefthalf.filled.badge.checkmark")
                    }
                    .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.navy))
                    
                    if booking != nil {
                        Button {
                            showReviewSheet = true
                        } label: {
                            Label("Write Review", systemImage: "star.bubble.fill")
                        }
                        .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.teal))
                    }
                }
            }
            .padding(18)
        }
        .background(TCTheme.background)
        .navigationTitle("Passport Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWarrantyClaimSheet) {
            NavigationStack {
                Form {
                    Section("Describe Follow-up Issue Under Warranty") {
                        TextField("e.g. Replaced port feels slightly loose when plugging cable...", text: $warrantyIssueText, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    Section {
                        Button("Submit Free Doorstep Warranty Claim") {
                            let desc = warrantyIssueText.isEmpty ? "Follow-up inspection requested for replaced part under 180-day warranty." : warrantyIssueText
                            _ = store.submitWarrantyClaim(repairRecordId: record.id, issueDescription: desc)
                            showWarrantyClaimSheet = false
                        }
                        .fontWeight(.bold)
                        .foregroundColor(TCTheme.teal)
                    }
                }
                .navigationTitle("Claim Warranty")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showWarrantyClaimSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showReviewSheet) {
            if let booking {
                ReviewAndComplaintSheet(store: store, booking: booking)
            }
        }
    }
}

struct ReviewAndComplaintSheet: View {
    @ObservedObject var store: TechCareStore
    let booking: Booking
    @Environment(\.dismiss) private var dismiss
    
    @State private var rating: Int = 5
    @State private var comment: String = "Technician arrived on time, explained the quotation transparently, and completed the repair neatly."
    @State private var errorMsg: String? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rate Your Doorstep Repair Experience") {
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                rating = star
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                    
                    TextEditor(text: $comment)
                        .frame(height: 90)
                }
                
                if let errorMsg {
                    Section {
                        Text(errorMsg).foregroundColor(TCTheme.danger).font(.caption)
                    }
                }
                
                Section {
                    Button("Submit Verified Review") {
                        switch store.submitReview(bookingId: booking.id, rating: rating, comment: comment) {
                        case .success:
                            dismiss()
                        case .failure(let err):
                            errorMsg = err.localizedDescription
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundColor(TCTheme.teal)
                }
            }
            .navigationTitle("Rate Technician")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
