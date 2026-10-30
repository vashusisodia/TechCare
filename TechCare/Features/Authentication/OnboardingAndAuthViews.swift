import SwiftUI

// MARK: - Section 7.1: Onboarding, Welcome & Demo Authentication

struct OnboardingAndAuthView: View {
    @ObservedObject var store: TechCareStore
    @State private var currentPage: Int = 0
    @State private var showAuthSheet: Bool = false
    
    private let slides: [(icon: String, badge: String, title: String, subtitle: String)] = [
        (
            "wrench.and.screwdriver.fill",
            "DOORSTEP ELECTRONICS REPAIR",
            "Verified Technicians at Your Home",
            "Watch your phone, laptop, tablet, or gadget get inspected right at your table—no mystery part swapping."
        ),
        (
            "doc.text.magnifyingglass",
            "100% TRANSPARENT QUOTATIONS",
            "Approve the Quote Before Any Repair Starts",
            "Receive an itemised parts & labour breakdown after inspection. Technicians cannot start work or add extra charges without your explicit approval."
        ),
        (
            "lock.shield.fill",
            "PRIVACY & REPAIR PASSPORT",
            "Zero Data Snooping & 180-Day Warranty",
            "Guided privacy checklist, pay only after confirming completion, and keep a permanent digital Repair Passport & GST invoice."
        )
    ]
    
    var body: some View {
        ZStack {
            TCTheme.background.ignoresSafeArea()
            
            VStack(spacing: 22) {
                HStack {
                    HStack(spacing: 8) {
                        TechCareLogoView(size: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("TechCare")
                                .font(.headline.weight(.bold))
                            Text("India • INR (₹)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button("Skip to Demo") {
                        store.hasCompletedOnboarding = true
                        store.isAuthenticated = true
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(TCTheme.teal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(TCTheme.tealSoft)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
                
                TabView(selection: $currentPage) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        let slide = slides[index]
                        VStack(spacing: 20) {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [TCTheme.teal.opacity(0.22), Color.clear],
                                            center: .center,
                                            startRadius: 12,
                                            endRadius: 120
                                        )
                                    )
                                    .frame(width: 220, height: 220)
                                
                                TechCareLogoView(size: 102)
                            }
                            
                            TCBadge(text: slide.badge, icon: slide.icon, color: TCTheme.teal)
                            
                            Text(slide.title)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            
                            Text(slide.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 28)
                            
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                VStack(spacing: 12) {
                    Button {
                        store.switchRole(to: .customer)
                        store.hasCompletedOnboarding = true
                        store.isAuthenticated = true
                    } label: {
                        HStack {
                            Image(systemName: "bolt.shield.fill")
                            Text("Launch Instant Demo (Customer Mode)")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(TCPrimaryButtonStyle())
                    
                    HStack(spacing: 10) {
                        Button {
                            store.switchRole(to: .technician)
                            store.hasCompletedOnboarding = true
                            store.isAuthenticated = true
                        } label: {
                            Label("Technician Demo", systemImage: "wrench.and.screwdriver.fill")
                        }
                        .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.teal))
                        
                        Button {
                            showAuthSheet = true
                        } label: {
                            Label("Sign In / Register", systemImage: "person.badge.key.fill")
                        }
                        .buttonStyle(TCSecondaryButtonStyle(tint: TCTheme.deepBlue))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthLoginRegisterSheet(store: store)
        }
    }
}

struct AuthLoginRegisterSheet: View {
    @ObservedObject var store: TechCareStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRegistering: Bool = false
    @State private var fullName: String = "Aarav Sharma"
    @State private var phoneOrEmail: String = "+91 98765 43210"
    @State private var otpOrPasscode: String = ""
    @State private var selectedRole: UserRole = .customer
    @State private var validationError: String? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        TechCareLogoView(size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isRegistering ? "Create TechCare Account" : "Sign In to TechCare")
                                .font(.title3.weight(.bold))
                            Text("Expert Gadget Repair. At Your Doorstep.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    Picker("Mode", selection: $isRegistering) {
                        Text("Sign In").tag(false)
                        Text("Register").tag(true)
                    }
                    .pickerStyle(.segmented)
                    
                    TCCard {
                        VStack(alignment: .leading, spacing: 14) {
                            if isRegistering {
                                TCFormField(label: "Full Name", required: true) {
                                    TextField("e.g. Aarav Sharma", text: $fullName)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            
                            TCFormField(label: "Mobile Number or Email (India)", required: true) {
                                TextField("+91 98765 43210 or email", text: $phoneOrEmail)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            TCFormField(label: "One-Time Passcode (OTP) / Password", required: true) {
                                SecureField("Enter 6-digit OTP or password", text: $otpOrPasscode)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            TCFormField(label: "Demo Account Role") {
                                Picker("Account Role", selection: $selectedRole) {
                                    ForEach(UserRole.allCases) { role in
                                        Text(role.rawValue).tag(role)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            if let validationError {
                                Label(validationError, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(TCTheme.danger)
                            }
                            
                            Label("Security Note: Passwords are never stored in plain text. Production auth uses token-based OTP/OAuth.", systemImage: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        if phoneOrEmail.trimmingCharacters(in: .whitespaces).count < 5 {
                            validationError = "Please enter a valid Indian mobile number or email."
                            return
                        }
                        if isRegistering && fullName.trimmingCharacters(in: .whitespaces).isEmpty {
                            validationError = "Please enter your full name."
                            return
                        }
                        if !fullName.trimmingCharacters(in: .whitespaces).isEmpty {
                            store.currentUser.name = fullName
                        }
                        store.currentUser.phone = phoneOrEmail
                        store.switchRole(to: selectedRole)
                        store.hasCompletedOnboarding = true
                        store.isAuthenticated = true
                        dismiss()
                    } label: {
                        Text(isRegistering ? "Create Account & Continue" : "Verify & Sign In")
                    }
                    .buttonStyle(TCPrimaryButtonStyle())
                    
                    Button {
                        store.hasCompletedOnboarding = true
                        store.isAuthenticated = true
                        dismiss()
                    } label: {
                        Text("Use One-Tap Prototype Demo Account")
                    }
                    .buttonStyle(TCSecondaryButtonStyle())
                }
                .padding(20)
            }
            .background(TCTheme.background)
            .navigationTitle("Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
