import SwiftUI

// MARK: - Sections 7.6, 7.7 & 7.8: Technician Discovery, Filtering, Profile, Appointment Booking & Confirmation

struct TechnicianDiscoveryAndBookingView: View {
    @ObservedObject var store: TechCareStore
    
    @State private var filterOnlyOnline: Bool = true
    @State private var minimumRating: Double = 4.5
    @State private var selectedAreaFilter: String = "All Areas"
    @State private var selectedSkillFilter: String = "All Skills"
    @State private var showBookingSheetForTech: Technician? = nil
    @State private var confirmedBooking: Booking? = nil
    @State private var errorAlertMessage: String? = nil
    
    let timeSlots = [
        "10:00 AM - 12:00 PM",
        "12:00 PM - 02:00 PM",
        "02:00 PM - 04:00 PM",
        "04:00 PM - 06:00 PM",
        "06:00 PM - 08:00 PM"
    ]
    
    var rankedTechnicians: [SmartTechnicianAllocator.ScoredTechnician] {
        let base = SmartTechnicianAllocator.rankTechnicians(
            candidates: store.technicians,
            category: store.draftCategory,
            brand: store.draftBrand,
            issue: store.draftIssue,
            preferredArea: store.draftSelectedAddress.area,
            appointmentSlot: store.draftTimeSlot,
            existingBookings: store.bookings
        )
        return base.filter { item in
            let tech = item.technician
            let ratingOK = tech.rating >= minimumRating
            let onlineOK = !filterOnlyOnline || tech.isAvailableOnline
            let areaOK = selectedAreaFilter == "All Areas" || tech.serviceArea.localizedCaseInsensitiveContains(selectedAreaFilter)
            let skillOK = selectedSkillFilter == "All Skills" || tech.skills.contains(selectedSkillFilter)
            return ratingOK && onlineOK && areaOK && skillOK
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TCBadge(text: "STEP 2 OF 3 • SMART TECHNICIAN MATCHING", icon: "person.badge.shield.checkmark.fill", color: TCTheme.teal)
                
                // Request Summary Card
                TCCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: store.draftCategory.icon)
                                .foregroundColor(TCTheme.teal)
                            Text("\(store.draftBrand) \(store.draftModel)")
                                .font(.headline)
                            Spacer()
                            TCBadge(text: store.draftWarrantyStatus.rawValue, color: TCTheme.deepBlue)
                        }
                        Text("Reported Issue: \(store.draftIssue.rawValue)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(TCTheme.teal)
                        Text(store.draftSymptomDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                // Filter Bar (Section 7.6)
                TCCard(padding: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Filter Specialists (Demo Sample Data)", systemImage: "line.3.horizontal.decrease.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundColor(TCTheme.navy)
                            Spacer()
                            Toggle("Available Now", isOn: $filterOnlyOnline)
                                .labelsHidden()
                                .tint(TCTheme.teal)
                            Text("Available Only")
                                .font(.caption2)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Menu {
                                    Button("All Ratings") { minimumRating = 0.0 }
                                    Button("4.5★ & Above") { minimumRating = 4.5 }
                                    Button("4.8★ & Above") { minimumRating = 4.8 }
                                } label: {
                                    filterChipLabel("Rating ≥ \(String(format: "%.1f", minimumRating))★")
                                }
                                
                                Menu {
                                    Button("All Areas") { selectedAreaFilter = "All Areas" }
                                    Button("Noida") { selectedAreaFilter = "Noida" }
                                    Button("Greater Noida") { selectedAreaFilter = "Greater Noida" }
                                    Button("Sector 62") { selectedAreaFilter = "Sector 62" }
                                } label: {
                                    filterChipLabel("Area: \(selectedAreaFilter)")
                                }
                                
                                Menu {
                                    Button("All Skills") { selectedSkillFilter = "All Skills" }
                                    ForEach(IssueCategory.allCases) { ic in
                                        Button(ic.requiredSkillTag) {
                                            selectedSkillFilter = ic.requiredSkillTag
                                        }
                                    }
                                } label: {
                                    filterChipLabel("Skill: \(selectedSkillFilter)")
                                }
                            }
                        }
                    }
                }
                
                if rankedTechnicians.isEmpty {
                    TCEmptyStateView(
                        icon: "person.crop.circle.badge.exclamationmark",
                        title: "No Matching Doorstep Technician in Slot",
                        message: "No technician matches all current filters or time slot. You can relax filters or book with Smart Auto-Allocation / Workshop Pickup.",
                        buttonTitle: "Reset Filters"
                    ) {
                        minimumRating = 4.0
                        selectedAreaFilter = "All Areas"
                        selectedSkillFilter = "All Skills"
                        filterOnlyOnline = false
                    }
                } else {
                    ForEach(rankedTechnicians) { scored in
                        VStack(alignment: .leading, spacing: 8) {
                            NavigationLink(destination: TechnicianProfileDetailView(store: store, technician: scored.technician)) {
                                TechnicianSummaryCard(
                                    technician: scored.technician,
                                    matchReasons: scored.matchReasons
                                )
                            }
                            .buttonStyle(.plain)
                            
                            HStack(spacing: 10) {
                                NavigationLink(destination: TechnicianProfileDetailView(store: store, technician: scored.technician)) {
                                    Text("View Full Profile & Reviews")
                                }
                                .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.deepBlue))
                                
                                Button {
                                    store.draftSelectedTechnician = scored.technician
                                    showBookingSheetForTech = scored.technician
                                } label: {
                                    Text("Select & Book (\(INRFormatter.format(scored.technician.visitDiagnosticFeeINR)) Visit)")
                                }
                                .buttonStyle(TCPrimaryButtonStyle(useTeal: true))
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(TCTheme.background)
        .navigationTitle("Select Technician")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showBookingSheetForTech) { tech in
            AppointmentCheckoutSheet(
                store: store,
                technician: tech,
                timeSlots: timeSlots
            ) { createdBooking in
                confirmedBooking = createdBooking
            }
        }
        .navigationDestination(item: $confirmedBooking) { booking in
            BookingConfirmationSuccessView(store: store, booking: booking)
        }
    }
    
    private func filterChipLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption2.weight(.semibold))
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemFill))
        .foregroundColor(.primary)
        .clipShape(Capsule())
    }
}

// MARK: - Section 7.7: Technician Profile Detail Screen

struct TechnicianProfileDetailView: View {
    @ObservedObject var store: TechCareStore
    let technician: Technician
    @State private var showBookingSheet: Bool = false
    @State private var createdBooking: Booking? = nil
    
    var techReviews: [Review] {
        store.reviews(for: technician.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header Identity Card
                TCCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(TCTheme.heroGradient)
                                    .frame(width: 68, height: 68)
                                Text(technician.initials)
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(technician.name)
                                        .font(.title3.weight(.bold))
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(TCTheme.teal)
                                }
                                TCBadge(
                                    text: technician.verificationStatus.rawValue,
                                    icon: "person.badge.shield.checkmark.fill",
                                    color: TCTheme.teal
                                )
                                Text("Service Area: \(technician.serviceArea)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack(spacing: 10) {
                            statPill(title: "Rating", value: String(format: "%.1f ★", technician.rating))
                            statPill(title: "Reviews", value: "\(technician.reviewsCount)")
                            statPill(title: "Repairs", value: "\(technician.completedJobs)+")
                            statPill(title: "Visit Fee", value: INRFormatter.format(technician.visitDiagnosticFeeINR))
                        }
                    }
                }
                
                // Verification vs Technical Qualifications Disclosure (Section 7.7 requirement)
                TCCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Verification & Qualification Disclosure", systemImage: "shield.lefthalf.filled")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(TCTheme.navy)
                        
                        Text(technician.qualificationSummary)
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Text("Transparency Policy: TechCare distinguishes government identity verification from technical trade qualifications. In this prototype, verification badges represent demo sample records. Independent technicians are not claimed to be manufacturer-authorised unless explicitly documented.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(10)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                
                // Skills & Supported Categories
                TCCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Supported Categories & Technical Skills")
                            .font(.subheadline.weight(.bold))
                        
                        HStack(spacing: 8) {
                            ForEach(technician.supportedCategories) { cat in
                                TCBadge(text: cat.shortName, icon: cat.icon, color: TCTheme.deepBlue)
                            }
                        }
                        
                        FlowTagsView(tags: technician.skills)
                        
                        Divider()
                        
                        HStack {
                            Label("Working Hours: \(technician.workingHours)", systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Radius: \(technician.serviceRadiusKm) km")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(TCTheme.teal)
                        }
                    }
                }
                
                // Customer Reviews
                TCCard {
                    VStack(alignment: .leading, spacing: 12) {
                        TCSectionHeader(
                            title: "Verified Customer Reviews (\(techReviews.count) shown)",
                            subtitle: "Only customers with completed repairs can leave a review"
                        )
                        
                        if techReviews.isEmpty {
                            Text("No detailed reviews recorded in local store yet.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(techReviews) { rev in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(rev.customerName)
                                            .font(.caption.weight(.bold))
                                        Text("• \(rev.deviceSummary)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        HStack(spacing: 2) {
                                            ForEach(0..<rev.rating, id: \.self) { _ in
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                    Text(rev.comment)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                
                Button {
                    showBookingSheet = true
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                        Text("Book Doorstep Visit with \(technician.name)")
                    }
                }
                .buttonStyle(TCPrimaryButtonStyle())
            }
            .padding(18)
        }
        .background(TCTheme.background)
        .navigationTitle("Technician Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBookingSheet) {
            AppointmentCheckoutSheet(
                store: store,
                technician: technician,
                timeSlots: [
                    "10:00 AM - 12:00 PM",
                    "12:00 PM - 02:00 PM",
                    "02:00 PM - 04:00 PM",
                    "04:00 PM - 06:00 PM"
                ]
            ) { booking in
                createdBooking = booking
            }
        }
        .navigationDestination(item: $createdBooking) { booking in
            BookingConfirmationSuccessView(store: store, booking: booking)
        }
    }
    
    private func statPill(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Section 7.8: Appointment Booking Sheet & Address Selection

struct AppointmentCheckoutSheet: View {
    @ObservedObject var store: TechCareStore
    let technician: Technician
    let timeSlots: [String]
    var onBookingCreated: (Booking) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddressSheet: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TCCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Booking Summary")
                                .font(.headline)
                            HStack {
                                Text("Device:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(store.draftBrand) \(store.draftModel)")
                                    .fontWeight(.semibold)
                            }
                            .font(.caption)
                            
                            HStack {
                                Text("Issue:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(store.draftIssue.rawValue)
                                    .fontWeight(.semibold)
                                    .foregroundColor(TCTheme.teal)
                            }
                            .font(.caption)
                            
                            HStack {
                                Text("Assigned Specialist:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(technician.name)
                                    .fontWeight(.semibold)
                            }
                            .font(.caption)
                        }
                    }
                    
                    // Address Selector
                    TCCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Service Address", systemImage: "house.fill")
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Button("Change / Add") {
                                    showAddressSheet = true
                                }
                                .font(.caption.weight(.bold))
                                .foregroundColor(TCTheme.teal)
                            }
                            
                            Text(store.draftSelectedAddress.label)
                                .font(.caption.weight(.bold))
                                .foregroundColor(TCTheme.teal)
                            Text(store.draftSelectedAddress.fullFormatted)
                                .font(.caption)
                                .foregroundColor(.primary)
                            Text("Landmark: \(store.draftSelectedAddress.landmark)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Date & Time Slot
                    TCCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preferred Date & Time Slot")
                                .font(.subheadline.weight(.bold))
                            
                            DatePicker(
                                "Visit Date",
                                selection: $store.draftAppointmentDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .font(.caption.weight(.semibold))
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(timeSlots, id: \.self) { slot in
                                    let selected = store.draftTimeSlot == slot
                                    Button {
                                        store.draftTimeSlot = slot
                                    } label: {
                                        Text(slot)
                                            .font(.caption2.weight(.semibold))
                                            .padding(.vertical, 9)
                                            .frame(maxWidth: .infinity)
                                            .background(selected ? TCTheme.teal : Color(.tertiarySystemFill))
                                            .foregroundColor(selected ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            TCFormField(label: "Special Arrival Instructions") {
                                TextField("Gate code, parking or landmark note", text: $store.draftSpecialInstructions)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    
                    // Visit / Diagnostic Fee Disclosure
                    TCCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Transparent Fee Policy", systemImage: "indianrupeesign.circle.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(TCTheme.navy)
                                Spacer()
                                Text(INRFormatter.format(technician.visitDiagnosticFeeINR))
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(TCTheme.teal)
                            }
                            Text("• You pay ₹0 right now.\n• After doorstep inspection, \(technician.name) will submit an itemised repair quotation.\n• If you approve the repair quote, the \(INRFormatter.format(technician.visitDiagnosticFeeINR)) visit fee is waived into the repair.\n• If you decline the quote, only the \(INRFormatter.format(technician.visitDiagnosticFeeINR)) diagnostic visit fee is payable.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                    }
                    
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(TCTheme.danger)
                    }
                    
                    Button {
                        switch store.createBookingFromDraft(chosenTechnician: technician) {
                        case .success(let booking):
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onBookingCreated(booking)
                            }
                        case .failure(let err):
                            errorMessage = err.localizedDescription
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                            Text("Confirm Doorstep Booking (Pay ₹0 Now)")
                        }
                    }
                    .buttonStyle(TCPrimaryButtonStyle())
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("Confirm Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddressSheet) {
                AddressSelectorSheet(store: store)
            }
        }
    }
}

struct AddressSelectorSheet: View {
    @ObservedObject var store: TechCareStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showNewAddressForm: Bool = false
    @State private var label: String = "Home"
    @State private var line1: String = ""
    @State private var area: String = ""
    @State private var city: String = "Noida, UP"
    @State private var pincode: String = "201301"
    @State private var landmark: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Saved Service Addresses") {
                    ForEach(store.currentUser.savedAddresses) { addr in
                        Button {
                            store.draftSelectedAddress = addr
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(addr.label)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.primary)
                                    Text(addr.fullFormatted)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if store.draftSelectedAddress.id == addr.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(TCTheme.teal)
                                }
                            }
                        }
                    }
                }
                
                Section("Add New Address") {
                    TextField("Label (e.g. Parents' Home)", text: $label)
                    TextField("Flat / House No. & Building", text: $line1)
                    TextField("Sector / Locality", text: $area)
                    TextField("City & State", text: $city)
                    TextField("6-digit PIN Code", text: $pincode)
                        .keyboardType(.numberPad)
                    TextField("Nearby Landmark", text: $landmark)
                    
                    Button("Save & Select Address") {
                        guard !line1.isEmpty, !area.isEmpty else { return }
                        let newAddr = SavedAddress(
                            label: label,
                            line1: line1,
                            area: area,
                            city: city,
                            pincode: pincode,
                            landmark: landmark
                        )
                        store.currentUser.savedAddresses.append(newAddr)
                        store.draftSelectedAddress = newAddr
                        store.saveState()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(TCTheme.teal)
                }
            }
            .navigationTitle("Select Service Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Section 7.8: Booking Confirmation Screen

struct BookingConfirmationSuccessView: View {
    @ObservedObject var store: TechCareStore
    let booking: Booking
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(TCTheme.success.opacity(0.15))
                        .frame(width: 92, height: 92)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 46))
                        .foregroundColor(TCTheme.success)
                }
                .padding(.top, 16)
                
                TCBadge(text: "BOOKING CONFIRMED", icon: "sparkles", color: TCTheme.success)
                
                Text("Booking ID: \(booking.bookingCode)")
                    .font(.title2.monospaced().weight(.bold))
                
                Text("Your doorstep inspection request has been registered. No repair work or extra charge will occur until you approve the digital quotation after diagnosis.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                TCCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What Happens Next?")
                            .font(.subheadline.weight(.bold))
                        Label("1. Technician arrives during \(booking.timeSlot)", systemImage: "car.fill")
                            .font(.caption)
                        Label("2. In-person diagnosis & itemised quote submitted in app", systemImage: "doc.text.magnifyingglass")
                            .font(.caption)
                        Label("3. You review & approve the quote before repair starts", systemImage: "hand.thumbsup.fill")
                            .font(.caption)
                        Label("4. 5-point testing, customer confirmation, payment & 180-day Repair Passport", systemImage: "checkmark.shield.fill")
                            .font(.caption)
                    }
                }
                
                NavigationLink(destination: BookingDetailAndTrackingView(store: store, bookingId: booking.id)) {
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                        Text("Open Live Booking Tracker & Quote Approvals")
                    }
                }
                .buttonStyle(TCPrimaryButtonStyle())
            }
            .padding(20)
        }
        .background(TCTheme.background)
        .navigationTitle("Booking Confirmed")
        .navigationBarTitleDisplayMode(.inline)
    }
}
