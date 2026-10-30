import SwiftUI

// MARK: - Section 7.13: Payment Simulator & Itemised GST Invoice Views

struct PaymentSimulatorSheet: View {
    @ObservedObject var store: TechCareStore
    let bookingId: UUID
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMethod: PaymentMethod = .upi
    @State private var selectedUPIApp: String = "Google Pay"
    @State private var isVerifyingWithServer: Bool = false
    @State private var generatedInvoice: Invoice? = nil
    @State private var errorMessage: String? = nil
    
    let upiApps = ["Google Pay", "PhonePe", "Paytm", "BHIM UPI"]
    
    var booking: Booking? {
        store.bookings.first { $0.id == bookingId }
    }
    
    var approvedQuote: RepairQuote? {
        store.latestQuote(for: bookingId)
    }
    
    var payableAmount: Decimal {
        if let q = approvedQuote, q.approvalStatus == .approved {
            return q.totalAmountINR
        }
        return booking?.disclosedVisitFeeINR ?? 249
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Demo Mode Banner (Section 7.13 requirement)
                    TCCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TCBadge(text: "DEMO PAYMENT SIMULATOR (SANDBOX)", icon: "checkmark.shield.fill", color: TCTheme.navy)
                                Spacer()
                            }
                            Text("No real money is charged and no raw card details are collected or stored on the client. In production, payments use Razorpay Server-Side Orders & Webhook Verification.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Payable Breakdown
                    TCCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Payment Summary")
                                .font(.headline)
                            
                            if let q = approvedQuote, q.approvalStatus == .approved {
                                HStack {
                                    Text("Approved Parts Total")
                                    Spacer()
                                    Text(INRFormatter.format(q.partsCostINR))
                                }
                                .font(.caption)
                                
                                HStack {
                                    Text("Repair & Calibration Labour")
                                    Spacer()
                                    Text(INRFormatter.format(q.labourCostINR))
                                }
                                .font(.caption)
                                
                                HStack {
                                    Text("Doorstep Visit Fee")
                                    Spacer()
                                    Text(q.visitFeeWaivedOnApproval ? "Waived (₹0)" : INRFormatter.format(q.visitOrDiagnosticFeeINR))
                                        .foregroundColor(q.visitFeeWaivedOnApproval ? TCTheme.success : .primary)
                                }
                                .font(.caption)
                                
                                HStack {
                                    Text("GST (18%)")
                                    Spacer()
                                    Text(INRFormatter.format(q.applicableTaxesINR))
                                }
                                .font(.caption)
                            } else {
                                HStack {
                                    Text("Disclosed Doorstep Inspection / Visit Fee")
                                    Spacer()
                                    Text(INRFormatter.format(payableAmount))
                                }
                                .font(.caption)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total Payable (INR)")
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Text(INRFormatter.format(payableAmount))
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(TCTheme.teal)
                            }
                        }
                    }
                    
                    // Payment Method Selection
                    TCCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Payment Method")
                                .font(.subheadline.weight(.bold))
                            
                            ForEach(PaymentMethod.allCases) { method in
                                Button {
                                    selectedMethod = method
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: method.icon)
                                            .font(.title3)
                                            .foregroundColor(selectedMethod == method ? TCTheme.teal : .secondary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(method.rawValue)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.primary)
                                            if method == .card {
                                                Text("Tokenised checkout via gateway sheet; no card numbers entered in app")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: selectedMethod == method ? "largecircle.fill.circle" : "circle")
                                            .foregroundColor(selectedMethod == method ? TCTheme.teal : .secondary)
                                    }
                                    .padding(12)
                                    .background(selectedMethod == method ? TCTheme.tealSoft : Color(.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if selectedMethod == .upi {
                                HStack(spacing: 8) {
                                    ForEach(upiApps, id: \.self) { app in
                                        Button {
                                            selectedUPIApp = app
                                        } label: {
                                            Text(app)
                                                .font(.caption2.weight(.bold))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(selectedUPIApp == app ? TCTheme.navy : Color(.tertiarySystemFill))
                                                .foregroundColor(selectedUPIApp == app ? .white : .primary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor(TCTheme.danger)
                    }
                    
                    if let generatedInvoice {
                        NavigationLink(destination: InvoiceDetailView(invoice: generatedInvoice)) {
                            HStack {
                                Image(systemName: "doc.richtext.fill")
                                Text("Payment Verified! View Invoice \(generatedInvoice.invoiceNumber)")
                            }
                        }
                        .buttonStyle(TCPrimaryButtonStyle(useTeal: true))
                    } else {
                        Button {
                            isVerifyingWithServer = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                isVerifyingWithServer = false
                                switch store.processSimulatedPayment(bookingId: bookingId, method: selectedMethod) {
                                case .success(let invoice):
                                    generatedInvoice = invoice
                                case .failure(let err):
                                    errorMessage = err.localizedDescription
                                }
                            }
                        } label: {
                            HStack {
                                if isVerifyingWithServer {
                                    ProgressView().tint(.white)
                                    Text("Verifying Gateway Signature...")
                                } else {
                                    Image(systemName: "lock.shield.fill")
                                    Text("Simulate Verified Payment of \(INRFormatter.format(payableAmount))")
                                }
                            }
                        }
                        .buttonStyle(TCPrimaryButtonStyle(isDisabled: isVerifyingWithServer))
                        .disabled(isVerifyingWithServer)
                    }
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("Payment Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct InvoiceDetailView: View {
    let invoice: Invoice
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TCCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            HStack(spacing: 10) {
                                TechCareLogoView(size: 42)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("TechCare India Pvt. Ltd. (Demo)")
                                        .font(.subheadline.weight(.bold))
                                    Text("Tax Invoice & Warranty Certificate")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            TCBadge(text: "PAID", icon: "checkmark.seal.fill", color: TCTheme.success)
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("INVOICE NO")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text(invoice.invoiceNumber)
                                    .font(.caption.monospaced().weight(.bold))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("ISSUE DATE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text(invoice.issueDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("BILLED TO")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text(invoice.customerName)
                                    .font(.caption.weight(.semibold))
                                Text("Device: \(invoice.deviceSummary)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("SERVICED BY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text(invoice.technicianName)
                                    .font(.caption.weight(.semibold))
                                Text(invoice.paymentMethod.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(TCTheme.teal)
                            }
                        }
                        
                        Divider()
                        
                        Text("ITEMISED CHARGES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        ForEach(invoice.itemisedCharges) { item in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.caption.weight(.semibold))
                                    Text(item.subtitle)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(INRFormatter.format(item.amountINR))
                                    .font(.caption.weight(.bold))
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Subtotal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(INRFormatter.format(invoice.subtotalINR))
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("GST (18%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(INRFormatter.format(invoice.taxAmountINR))
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Grand Total Paid")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            Text(INRFormatter.format(invoice.totalAmountINR))
                                .font(.title3.weight(.bold))
                                .foregroundColor(TCTheme.navy)
                        }
                    }
                }
                
                TCCard {
                    Label("This digital invoice is linked to your Device Repair Passport for hassle-free 180-day doorstep warranty claims.", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(18)
        }
        .background(TCTheme.background)
        .navigationTitle("Tax Invoice")
        .navigationBarTitleDisplayMode(.inline)
    }
}
