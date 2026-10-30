import SwiftUI

// MARK: - Section 8.1, 9, 10 & 17: Customer Profile, Technician Onboarding Profile, Simulated Admin Operations Dashboard, Help & Support, and Built-In Unit Test Verifier

struct ProfileAndSettingsTabView: View {
    @ObservedObject var store: TechCareStore
    @State private var showTechOnboardingSheet: Bool = false
    @State private var showTestRunnerSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // User Identity & Role Switcher Card
                    TCCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(TCTheme.heroGradient)
                                        .frame(width: 58, height: 58)
                                    Image(systemName: store.activeRole.icon)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(store.currentUser.name)
                                        .font(.headline.weight(.bold))
                                    Text("\(store.currentUser.phone) • \(store.currentUser.email)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TCBadge(text: "ACTIVE DEMO MODE: \(store.activeRole.rawValue.uppercased())", color: TCTheme.teal)
                                }
                                Spacer()
                            }
                            
                            Divider()
                            
                            Text("Switch Active Prototype Persona (Development Only)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                            
                            Picker("Active Role", selection: Binding(
                                get: { store.activeRole },
                                set: { store.switchRole(to: $0) }
                            )) {
                                ForEach(UserRole.allCases) { role in
                                    Text(role.rawValue).tag(role)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Text("Production Security Note: In production, role permissions (Customer, Technician, Admin) are strictly enforced by backend JWT claims and RBAC middleware.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Registered Devices
                    TCCard {
                        VStack(alignment: .leading, spacing: 10) {
                            TCSectionHeader(title: "My Registered Devices (\(store.devices.count))", subtitle: "Linked with Repair Passports")
                            ForEach(store.devices) { dev in
                                HStack {
                                    Image(systemName: dev.category.icon)
                                        .foregroundColor(TCTheme.teal)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dev.displayName)
                                            .font(.caption.weight(.bold))
                                        Text("\(dev.category.rawValue) • Serial ••••\(dev.serialOrIMEIHint)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    TCBadge(text: dev.warrantyStatus.rawValue, color: TCTheme.deepBlue)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Technician Onboarding & Verification Form (Section 8.1)
                    TCCard {
                        VStack(alignment: .leading, spacing: 10) {
                            TCSectionHeader(
                                title: "Technician Partner Onboarding",
                                subtitle: "Register skills, service radius & demo verification"
                            )
                            Button {
                                showTechOnboardingSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Open Technician Onboarding Form")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.teal))
                        }
                    }
                    
                    // Built-in Business Rule Self-Test Suite (Section 17)
                    TCCard {
                        VStack(alignment: .leading, spacing: 10) {
                            TCSectionHeader(
                                title: "Stage 7 QA: Business Rule Unit Test Suite",
                                subtitle: "Verify 13 core booking, quote & payment rules live on device"
                            )
                            Button {
                                showTestRunnerSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.seal.text.page.fill")
                                    Text("Run Automated Business Rule Tests")
                                    Spacer()
                                    Image(systemName: "play.fill")
                                }
                            }
                            .buttonStyle(TCPrimaryButtonStyle(useTeal: true))
                        }
                    }
                    
                    // Support & Sign Out
                    NavigationLink(destination: HelpAndSupportCenterView(store: store)) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                            Text("Help, Privacy Policy & B2B Partnerships")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.navy))
                    
                    HStack(spacing: 10) {
                        Button(role: .destructive) {
                            store.resetToFreshDemoData()
                        } label: {
                            Label("Reset Demo Data", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.danger))
                        
                        Button {
                            store.hasCompletedOnboarding = false
                        } label: {
                            Label("Sign Out to Welcome", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .buttonStyle(TCSecondaryButtonStyle(tint: .secondary))
                    }
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showTechOnboardingSheet) {
                TechnicianOnboardingSheet(store: store)
            }
            .sheet(isPresented: $showTestRunnerSheet) {
                BusinessRuleSelfTestView()
            }
        }
    }
}

// MARK: - Section 8.1: Technician Onboarding Sheet

struct TechnicianOnboardingSheet: View {
    @ObservedObject var store: TechCareStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var phone: String = "+91 "
    @State private var serviceArea: String = "Noida & Greater Noida"
    @State private var workingHours: String = "10:00 AM – 07:00 PM"
    @State private var serviceRadiusKm: Int = 15
    @State private var experienceYears: Int = 5
    @State private var visitFeeString: String = "249"
    @State private var qualificationSummary: String = "Govt ID Submitted • 5+ Yrs Mobile & Laptop Repair Experience"
    @State private var selectedCategories: Set<DeviceCategory> = [.mobilePhone, .laptopDesktop]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Technician Identity & Contact") {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number (India)", text: $phone)
                        .keyboardType(.phonePad)
                    Stepper("Experience: \(experienceYears) Years", value: $experienceYears, in: 1...30)
                }
                
                Section("Supported Device Categories") {
                    ForEach(DeviceCategory.allCases) { cat in
                        Toggle(cat.rawValue, isOn: Binding(
                            get: { selectedCategories.contains(cat) },
                            set: { isOn in
                                if isOn { selectedCategories.insert(cat) }
                                else if selectedCategories.count > 1 { selectedCategories.remove(cat) }
                            }
                        ))
                    }
                }
                
                Section("Service Area, Working Hours & Visit Fee") {
                    TextField("Service Area", text: $serviceArea)
                    TextField("Working Hours", text: $workingHours)
                    Stepper("Service Radius: \(serviceRadiusKm) km", value: $serviceRadiusKm, in: 5...40)
                    TextField("Doorstep Diagnostic Visit Fee (₹)", text: $visitFeeString)
                        .keyboardType(.numberPad)
                }
                
                Section("Qualifications & Demo Verification") {
                    TextField("Qualifications Summary", text: $qualificationSummary, axis: .vertical)
                        .lineLimit(2...4)
                    Text("Note: New applications start in 'Govt ID Verified • Skill Assessment Pending' demo status until reviewed.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Submit Technician Partner Application") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let newTech = Technician(
                            name: name,
                            phone: phone,
                            skills: [
                                IssueCategory.brokenDisplay.requiredSkillTag,
                                IssueCategory.batteryReplacement.requiredSkillTag,
                                IssueCategory.overheatingPerf.requiredSkillTag
                            ],
                            supportedCategories: Array(selectedCategories),
                            supportedBrands: ["Apple", "Samsung", "Dell", "HP", "Lenovo", "OnePlus"],
                            serviceArea: serviceArea,
                            workingHours: workingHours,
                            serviceRadiusKm: serviceRadiusKm,
                            isAvailableOnline: true,
                            verificationStatus: .identityOnlyVerified,
                            qualificationSummary: qualificationSummary,
                            experienceYears: experienceYears,
                            rating: 4.8,
                            reviewsCount: 1,
                            completedJobs: 1,
                            visitDiagnosticFeeINR: Decimal(string: visitFeeString) ?? 249,
                            subscriptionTier: "Standard Partner",
                            latitude: 28.5355,
                            longitude: 77.3910
                        )
                        store.technicians.insert(newTech, at: 0)
                        store.selectedTechnicianAccountId = newTech.id
                        store.saveState()
                        store.showToast("Onboarded \(name) to TechCare!")
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(TCTheme.teal)
                }
            }
            .navigationTitle("Technician Onboarding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Section 9: Simulated Admin Operations Dashboard

struct SimulatedAdminDashboardView: View {
    @ObservedObject var store: TechCareStore
    
    var totalGrossVolumeINR: Decimal {
        store.invoices.reduce(0) { $0 + $1.totalAmountINR }
    }
    
    var estimatedPlatformRevenueINR: Decimal {
        ((totalGrossVolumeINR * store.platformCommissionPercent) / 100).roundedINR()
    }
    
    var cancelledBookings: [Booking] {
        store.bookings.filter { $0.status == .cancelled }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Simulated Admin Notice
                    TCCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TCBadge(text: "SIMULATED ADMIN CONSOLE (DEMO ONLY)", icon: "shield.lefthalf.filled", color: TCTheme.navy)
                                Spacer()
                                Button("Exit to Customer") {
                                    store.switchRole(to: .customer)
                                }
                                .font(.caption.weight(.bold))
                                .foregroundColor(TCTheme.teal)
                            }
                            Text("Security Architecture: In production, administrative endpoints are isolated in an authenticated internal web portal protected by multi-factor authentication and server-side RBAC.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Platform Analytics KPIs
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        adminMetric(title: "Total Bookings", value: "\(store.bookings.count)", sub: "\(store.bookings.filter { !$0.status.isTerminal }.count) Active", color: TCTheme.teal)
                        adminMetric(title: "Verified Technicians", value: "\(store.technicians.count)", sub: "\(store.technicians.filter { $0.isAvailableOnline }.count) Online", color: TCTheme.deepBlue)
                        adminMetric(title: "Invoiced GMV (INR)", value: INRFormatter.format(totalGrossVolumeINR), sub: "\(store.invoices.count) Invoices", color: TCTheme.success)
                        adminMetric(title: "Commission (\(NSDecimalNumber(decimal: store.platformCommissionPercent))%)", value: INRFormatter.format(estimatedPlatformRevenueINR), sub: "Before gateway costs", color: TCTheme.navy)
                    }
                    
                    // Configurable Platform Commission Rate (Section 10)
                    TCCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Business Model & Commission Configuration")
                                .font(.subheadline.weight(.bold))
                            
                            HStack {
                                Text("Platform Repair Commission:")
                                    .font(.caption.weight(.semibold))
                                Spacer()
                                Text("\(NSDecimalNumber(decimal: store.platformCommissionPercent))%")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(TCTheme.teal)
                            }
                            
                            HStack(spacing: 8) {
                                ForEach([Decimal(8), Decimal(10), Decimal(12), Decimal(15)], id: \.self) { rate in
                                    Button {
                                        store.platformCommissionPercent = rate
                                        store.saveState()
                                    } label: {
                                        Text("\(NSDecimalNumber(decimal: rate))%")
                                            .font(.caption.weight(.bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(store.platformCommissionPercent == rate ? TCTheme.navy : Color(.tertiarySystemFill))
                                            .foregroundColor(store.platformCommissionPercent == rate ? .white : .primary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            let sample2000Commission = ((Decimal(2000) * store.platformCommissionPercent) / 100).roundedINR()
                            Text("Live Example: A ₹2,000 approved repair at \(NSDecimalNumber(decimal: store.platformCommissionPercent))% yields \(INRFormatter.format(sample2000Commission)) platform commission before payment gateway and operating costs.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Technician Verification Management
                    TCCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Technician Roster & Verification Status")
                                .font(.subheadline.weight(.bold))
                            
                            ForEach(store.technicians) { tech in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tech.name)
                                            .font(.caption.weight(.bold))
                                        Text(tech.verificationStatus.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(TCTheme.teal)
                                    }
                                    Spacer()
                                    Menu("Update Badge") {
                                        ForEach(TechnicianVerificationStatus.allCases) { status in
                                            Button(status.rawValue) {
                                                if let idx = store.technicians.firstIndex(where: { $0.id == tech.id }) {
                                                    store.technicians[idx].verificationStatus = status
                                                    store.saveState()
                                                }
                                            }
                                        }
                                    }
                                    .font(.caption2.weight(.bold))
                                }
                                Divider()
                            }
                        }
                    }
                    
                    // Complaints & Disputes List
                    TCCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Customer Complaints & Disputes (\(store.complaints.count))")
                                .font(.subheadline.weight(.bold))
                            
                            ForEach(store.complaints) { comp in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("\(comp.bookingCode) • \(comp.customerName)")
                                            .font(.caption.weight(.bold))
                                        Spacer()
                                        TCBadge(text: comp.status, color: comp.status == "Resolved" ? TCTheme.success : TCTheme.warning)
                                    }
                                    Text(comp.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    
                    // Cancellation Records
                    TCCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cancellation Records (\(cancelledBookings.count))")
                                .font(.subheadline.weight(.bold))
                            if cancelledBookings.isEmpty {
                                Text("No cancelled bookings in current session.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(cancelledBookings) { cb in
                                    HStack {
                                        Text(cb.bookingCode)
                                            .font(.caption.monospaced().weight(.bold))
                                        Text(cb.cancellationInfo?.reason ?? "Cancelled")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("Fee: \(INRFormatter.format(cb.cancellationInfo?.cancellationFeeINR ?? 0))")
                                            .font(.caption2.weight(.bold))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("Admin Operations")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func adminMetric(title: String, value: String, sub: String, color: Color) -> some View {
        TCCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundColor(color)
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Section 7.2 & 10: Help, Support & B2B Partnerships View

struct HelpAndSupportCenterView: View {
    @ObservedObject var store: TechCareStore
    @State private var complaintCode: String = "TC-2026-8412"
    @State private var complaintText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TCCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "phone.bubble.fill")
                                .font(.title2)
                                .foregroundColor(TCTheme.teal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TechCare India Support Desk")
                                    .font(.headline)
                                Text("09:00 AM – 09:00 PM IST • Toll-Free: 1800-120-TECH")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text("Every doorstep booking includes quotation protection, anti-static handling guidelines, and a 180-day Repair Passport.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // FAQs
                TCCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Frequently Asked Questions")
                            .font(.subheadline.weight(.bold))
                        
                        faqItem(
                            q: "Can a technician start repairing or charge me extra without my approval?",
                            a: "No. Under TechCare's state machine rules, the technician must first inspect the device and submit an itemised digital quotation. Work cannot begin—and no additional charges can be added—until you explicitly tap Approve."
                        )
                        faqItem(
                            q: "What if I decline the quotation after diagnosis?",
                            a: "If you choose not to proceed with the repair quote, you only pay the upfront disclosed doorstep visit/diagnostic fee (₹199–₹299). If you approve the repair, the visit fee is waived into the repair bill."
                        )
                        faqItem(
                            q: "Can every motherboard or screen issue be repaired at home?",
                            a: "Most modular replacements (screens, batteries, charging ports, SSD/RAM upgrades, laptop fan servicing) are completed at your table. Complex BGA micro-soldering or dust-free OLED laminations are routed via insured Workshop Pickup & Drop-off."
                        )
                        faqItem(
                            q: "Do you offer Campus / Office AMC Partnerships?",
                            a: "Yes! TechCare supports B2B Maintenance Partnerships for college computer labs, startups, and co-working spaces with priority SLA and GST invoicing."
                        )
                    }
                }
                
                // Log Support Ticket
                TCCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Raise a Support Ticket or Escalation")
                            .font(.subheadline.weight(.bold))
                        TextField("Booking ID (e.g. TC-2026-8412)", text: $complaintCode)
                            .textFieldStyle(.roundedBorder)
                        TextField("Describe your question or issue...", text: $complaintText, axis: .vertical)
                            .lineLimit(3...5)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            guard !complaintText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            store.complaints.insert(
                                SupportComplaint(
                                    bookingCode: complaintCode,
                                    customerName: store.currentUser.name,
                                    category: "Customer Support Ticket",
                                    description: complaintText,
                                    status: "Open"
                                ),
                                at: 0
                            )
                            complaintText = ""
                            store.saveState()
                            store.showToast("Support ticket registered!")
                        } label: {
                            Text("Submit Support Ticket")
                        }
                        .buttonStyle(TCPrimaryButtonStyle(useTeal: true))
                    }
                }
            }
            .padding(18)
        }
        .background(TCTheme.background)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func faqItem(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(q)
                .font(.caption.weight(.bold))
                .foregroundColor(.primary)
            Text(a)
                .font(.caption2)
                .foregroundColor(.secondary)
            Divider().padding(.top, 4)
        }
    }
}
