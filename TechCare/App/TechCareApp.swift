import SwiftUI

// MARK: - Section 6 & 11: Single Application Entry Point & Role-Aware Navigation Coordinator

@main
struct TechCareApp: App {
    @StateObject private var store = TechCareStore()
    
    var body: some Scene {
        WindowGroup {
            TechCareRootCoordinatorView(store: store)
        }
    }
}

struct TechCareRootCoordinatorView: View {
    @ObservedObject var store: TechCareStore
    @State private var showSplash: Bool = true
    
    var body: some View {
        ZStack(alignment: .top) {
            if showSplash {
                TechCareSplashView()
                    .transition(.opacity)
            } else if !store.hasCompletedOnboarding {
                OnboardingAndAuthView(store: store)
                    .transition(.opacity)
            } else {
                roleBasedTabContainer
            }
            
            // Global Toast Notification Banner
            if let message = store.activeBannerMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.white)
                    Text(message)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(TCTheme.navy.opacity(0.95))
                .clipShape(Capsule())
                .shadow(radius: 6, y: 3)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
    
    @ViewBuilder
    private var roleBasedTabContainer: some View {
        switch store.activeRole {
        case .customer:
            // Customer Tab Bar (Section 6: 1. Home, 2. My Bookings, 3. Repair History, 4. Profile)
            TabView(selection: $store.selectedCustomerTab) {
                CustomerHomeView(store: store)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                MyBookingsListView(store: store)
                    .tabItem {
                        Label("My Bookings", systemImage: "calendar.badge.clock")
                    }
                    .tag(1)
                
                RepairHistoryAndPassportTabView(store: store)
                    .tabItem {
                        Label("Repair History", systemImage: "doc.text.below.ecg.fill")
                    }
                    .tag(2)
                
                ProfileAndSettingsTabView(store: store)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle.fill")
                    }
                    .tag(3)
            }
            .tint(TCTheme.teal)
            
        case .technician:
            // Technician Mode Tab Bar (Section 6: 1. Dashboard, 2. Job Requests, 3. Active Jobs, 4. Earnings, 5. Profile)
            TabView(selection: $store.selectedTechnicianTab) {
                TechnicianDashboardTabView(store: store)
                    .tabItem {
                        Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent")
                    }
                    .tag(0)
                
                TechnicianJobRequestsTabView(store: store)
                    .tabItem {
                        Label("Job Requests", systemImage: "bell.badge.fill")
                    }
                    .tag(1)
                
                TechnicianActiveJobsTabView(store: store)
                    .tabItem {
                        Label("Active Jobs", systemImage: "wrench.and.screwdriver.fill")
                    }
                    .tag(2)
                
                TechnicianEarningsTabView(store: store)
                    .tabItem {
                        Label("Earnings", systemImage: "indianrupeesign.circle.fill")
                    }
                    .tag(3)
                
                ProfileAndSettingsTabView(store: store)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle.fill")
                    }
                    .tag(4)
            }
            .tint(TCTheme.teal)
            
        case .admin:
            // Simulated Admin Mode
            TabView {
                SimulatedAdminDashboardView(store: store)
                    .tabItem {
                        Label("Operations", systemImage: "shield.lefthalf.filled")
                    }
                
                ProfileAndSettingsTabView(store: store)
                    .tabItem {
                        Label("Role & QA", systemImage: "person.badge.key.fill")
                    }
            }
            .tint(TCTheme.teal)
        }
    }
}

struct TechCareSplashView: View {
    var body: some View {
        ZStack {
            TCTheme.heroGradient.ignoresSafeArea()
            
            VStack(spacing: 16) {
                TechCareLogoView(size: 108)
                
                Text("TechCare")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Expert Gadget Repair. At Your Doorstep.")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
                
                ProgressView()
                    .tint(.white)
                    .padding(.top, 12)
            }
        }
    }
}
