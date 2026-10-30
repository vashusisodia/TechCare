import SwiftUI

// MARK: - Section 7.2: Customer Home Screen

struct CustomerHomeView: View {
    @ObservedObject var store: TechCareStore
    @State private var searchText: String = ""
    @State private var showAddressPickerSheet: Bool = false
    @State private var showAIAssistantSheet: Bool = false
    @State private var navigateToBookingWizard: Bool = false
    
    var filteredCategories: [DeviceCategory] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return DeviceCategory.allCases
        }
        return DeviceCategory.allCases.filter { cat in
            cat.rawValue.localizedCaseInsensitiveContains(searchText) ||
            cat.subtitle.localizedCaseInsensitiveContains(searchText) ||
            cat.sampleBrands.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    var activeBookings: [Booking] {
        store.bookings.filter { !$0.status.isTerminal }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Top Greeting, Location Selector & Role Switch Pill
                    topHeaderCard
                    
                    // 2. Search Bar + AI Symptom Assistant Shortcut
                    searchAndAIBar
                    
                    // 3. Active Booking / Action Required Banner (e.g. Quote Pending Approval)
                    if let urgentBooking = activeBookings.first {
                        activeBookingAlertCard(booking: urgentBooking)
                    }
                    
                    // 4. Device Category Cards (Phones, Laptops, Tablets, Other Gadgets)
                    VStack(alignment: .leading, spacing: 12) {
                        TCSectionHeader(
                            title: "Select Device Category",
                            subtitle: "Doorstep inspection & repair across 4 categories"
                        )
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(filteredCategories) { category in
                                Button {
                                    store.draftCategory = category
                                    store.draftBrand = category.sampleBrands.first ?? "Apple"
                                    store.draftModel = category.sampleModels(for: store.draftBrand).first ?? "Standard Model"
                                    store.draftIssue = category.supportedIssues.first ?? .brokenDisplay
                                    navigateToBookingWizard = true
                                } label: {
                                    DeviceCategoryCard(category: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 5. Popular Doorstep Repair Services (with indicative INR ranges)
                    popularServicesSection
                    
                    // 6. Featured Verified Technicians
                    featuredTechniciansSection
                    
                    // 7. How TechCare Protects You (Workflow + Privacy)
                    howTechCareWorksSection
                    
                    // 8. Quick Help & Support Card
                    supportFooterCard
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("TechCare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAddressPickerSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(TCTheme.teal)
                            Text(store.draftSelectedAddress.label)
                                .font(.caption.weight(.bold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(TCTheme.tealSoft)
                        .clipShape(Capsule())
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Switch Demo Role") {
                            ForEach(UserRole.allCases) { role in
                                Button {
                                    store.switchRole(to: role)
                                } label: {
                                    Label(role.rawValue, systemImage: role.icon)
                                }
                            }
                        }
                        Section("Demo Utilities") {
                            Button(role: .destructive) {
                                store.resetToFreshDemoData()
                            } label: {
                                Label("Reset Demo Data", systemImage: "arrow.counterclockwise")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.badge.gearshape.fill")
                            Text("Role")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(TCTheme.navy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemFill))
                        .clipShape(Capsule())
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToBookingWizard) {
                DeviceAndIssueWizardView(store: store)
            }
            .sheet(isPresented: $showAddressPickerSheet) {
                AddressSelectorSheet(store: store)
            }
            .sheet(isPresented: $showAIAssistantSheet) {
                AISymptomAssistantSheet(store: store) { selectedCategory, selectedIssue, notes in
                    store.draftCategory = selectedCategory
                    store.draftBrand = selectedCategory.sampleBrands.first ?? "Apple"
                    store.draftModel = selectedCategory.sampleModels(for: store.draftBrand).first ?? "Model"
                    store.draftIssue = selectedIssue
                    store.draftSymptomDescription = notes
                    navigateToBookingWizard = true
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var topHeaderCard: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: TCTheme.Radius.xl, style: .continuous)
                .fill(TCTheme.heroGradient)
            
            Image(systemName: "cpu.fill")
                .font(.system(size: 110))
                .foregroundColor(.white.opacity(0.08))
                .offset(x: 16, y: 18)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TCBadge(text: "VERIFIED DOORSTEP REPAIR", icon: "checkmark.shield.fill", color: .white)
                    Spacer()
                    Text("Visit from ₹199")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Text("Namaste, \(store.currentUser.name.components(separatedBy: " ").first ?? "Aarav")")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                Text("Expert Gadget Repair. At Your Doorstep.\nTransparent diagnosis, quote approval before work starts, and 180-day warranty.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(3)
                
                HStack(spacing: 10) {
                    Button {
                        navigateToBookingWizard = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Book a Home Repair")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(TCTheme.navy)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    
                    Button {
                        showAIAssistantSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                            Text("AI Symptom Check")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 2)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var searchAndAIBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search iPhone screen, MacBook overheating, SSD...", text: $searchText)
                    .font(.subheadline)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(TCTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: TCTheme.Radius.md, style: .continuous))
            
            Button {
                showAIAssistantSheet = true
            } label: {
                Image(systemName: "wand.and.stars")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(TCTheme.teal)
                    .clipShape(RoundedRectangle(cornerRadius: TCTheme.Radius.md, style: .continuous))
            }
            .accessibilityLabel("AI Issue Categorisation Assistant")
        }
    }
    
    private func activeBookingAlertCard(booking: Booking) -> some View {
        let dev = store.device(for: booking.deviceId)
        let tech = store.technician(for: booking.technicianId)
        let isQuotePending = booking.status == .quotePending
        
        return NavigationLink(destination: BookingDetailAndTrackingView(store: store, bookingId: booking.id)) {
            TCCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TCBadge(
                            text: booking.status.rawValue.uppercased(),
                            icon: isQuotePending ? "exclamationmark.bubble.fill" : "clock.badge.checkmark.fill",
                            color: isQuotePending ? TCTheme.warning : TCTheme.teal
                        )
                        Spacer()
                        Text(booking.bookingCode)
                            .font(.caption2.monospaced().weight(.bold))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(TCTheme.tealSoft)
                                .frame(width: 44, height: 44)
                            Image(systemName: dev?.category.icon ?? "iphone")
                                .font(.headline)
                                .foregroundColor(TCTheme.teal)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dev?.displayName ?? "Device Repair")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.primary)
                            Text("Technician: \(tech?.name ?? "Matching...") • \(booking.timeSlot)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                    }
                    
                    if isQuotePending, let quote = store.latestQuote(for: booking.id) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(TCTheme.warning)
                            Text("Action Required: Review & Approve Quote (\(INRFormatter.format(quote.totalAmountINR))) so repair can begin.")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TCTheme.warning.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var popularServicesSection: some View {
        let popularIssues: [(DeviceCategory, IssueCategory)] = [
            (.mobilePhone, .brokenDisplay),
            (.mobilePhone, .batteryReplacement),
            (.laptopDesktop, .overheatingPerf),
            (.laptopDesktop, .ramSsdUpgrade),
            (.tabletIPad, .chargingPort),
            (.otherGadget, .buttonJoystick)
        ]
        
        return VStack(alignment: .leading, spacing: 12) {
            TCSectionHeader(
                title: "Popular Doorstep Repairs",
                subtitle: "Indicative estimates shown; final price after inspection & quote approval"
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<popularIssues.count, id: \.self) { idx in
                        let pair = popularIssues[idx]
                        let range = pair.1.indicativeRangeINR
                        Button {
                            store.draftCategory = pair.0
                            store.draftBrand = pair.0.sampleBrands.first ?? "Apple"
                            store.draftModel = pair.0.sampleModels(for: store.draftBrand).first ?? "Model"
                            store.draftIssue = pair.1
                            navigateToBookingWizard = true
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(TCTheme.tealSoft)
                                            .frame(width: 36, height: 36)
                                        Image(systemName: pair.1.icon)
                                            .foregroundColor(TCTheme.teal)
                                    }
                                    Spacer()
                                    TCBadge(text: pair.0.shortName, color: TCTheme.deepBlue)
                                }
                                
                                Text(pair.1.rawValue)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text("Est: \(INRFormatter.format(range.min)) – \(INRFormatter.format(range.max))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(TCTheme.teal)
                                
                                Text("Non-guaranteed indicative range")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .frame(width: 210, alignment: .leading)
                            .background(TCTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: TCTheme.Radius.lg, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var featuredTechniciansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TCSectionHeader(
                title: "Verified Doorstep Specialists",
                subtitle: "Sample demo profiles • ID & skill verification disclosed transparently",
                actionTitle: "View All"
            ) {
                navigateToBookingWizard = true
            }
            
            ForEach(store.technicians.prefix(3)) { tech in
                NavigationLink(destination: TechnicianProfileDetailView(store: store, technician: tech)) {
                    TechnicianSummaryCard(technician: tech)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var howTechCareWorksSection: some View {
        TCCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .foregroundColor(TCTheme.teal)
                        .font(.title3)
                    Text("How TechCare Protects Your Device & Wallet")
                        .font(.subheadline.weight(.bold))
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    howStepRow(num: "1", title: "Privacy-First Preparation", desc: "Guided backup & maintenance-mode checklist. Technicians never access personal photos or chats.")
                    howStepRow(num: "2", title: "Mandatory Quote Approval", desc: "Technician inspects at home and submits an itemised quote. Work cannot start until you tap Approve.")
                    howStepRow(num: "3", title: "Pay After Completion + Passport", desc: "Verify 5-point functional tests, pay via UPI/Card (Demo), and get a 180-day Repair Passport.")
                }
                
                Divider()
                
                Label("Note: Complex BGA motherboard micro-soldering or cleanroom OLED laminations that cannot be safely completed at home are transparently routed via insured Workshop Pickup & Drop-off.", systemImage: "info.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func howStepRow(num: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(num)
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(TCTheme.teal))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var supportFooterCard: some View {
        NavigationLink(destination: HelpAndSupportCenterView(store: store)) {
            TCCard {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TCTheme.info.opacity(0.14))
                            .frame(width: 42, height: 42)
                        Image(systemName: "headphones.circle.fill")
                            .font(.title3)
                            .foregroundColor(TCTheme.info)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Need Help, Warranty Support, or Privacy Advice?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("Open TechCare Support, FAQs & Dispute Resolution Center")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct DeviceCategoryCard: View {
    let category: DeviceCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TCTheme.tealSoft)
                        .frame(width: 44, height: 44)
                    Image(systemName: category.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(TCTheme.teal)
                }
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            Text(category.rawValue)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(category.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(TCTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: TCTheme.Radius.lg, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
    }
}

struct TechnicianSummaryCard: View {
    let technician: Technician
    var matchReasons: [String] = []
    
    var body: some View {
        TCCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TCTheme.heroGradient)
                            .frame(width: 50, height: 50)
                        Text(technician.initials)
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            Text(technician.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.primary)
                            Image(systemName: technician.verificationStatus == .identityAndSkillsVerified ? "checkmark.seal.fill" : "person.text.rectangle.fill")
                                .font(.caption)
                                .foregroundColor(technician.verificationStatus == .identityAndSkillsVerified ? TCTheme.teal : TCTheme.info)
                        }
                        
                        Text(technician.verificationStatus.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(TCTheme.teal)
                        
                        Text("\(technician.serviceArea) • \(technician.experienceYears) yrs exp")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", technician.rating))
                                .font(.caption.weight(.bold))
                                .foregroundColor(.primary)
                        }
                        Text("\(technician.completedJobs) jobs")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("Visit: \(INRFormatter.format(technician.visitDiagnosticFeeINR))")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(TCTheme.navy)
                            .padding(.top, 2)
                    }
                }
                
                if !matchReasons.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(matchReasons, id: \.self) { reason in
                                TCBadge(text: reason, icon: "sparkle", color: TCTheme.teal)
                            }
                        }
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(technician.skills.prefix(3), id: \.self) { skill in
                                TCBadge(text: skill, color: TCTheme.deepBlue)
                            }
                        }
                    }
                }
            }
        }
    }
}
