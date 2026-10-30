import SwiftUI

// MARK: - TechCare Design System
// Palette: Navy / Deep Blue, Crisp White / Adaptive Surface, Subtle Teal Accent

enum TCTheme {
    // Primary Navy / Deep Blue
    static let navy = Color(red: 0.06, green: 0.14, blue: 0.28)
    static let navyLight = Color(red: 0.11, green: 0.22, blue: 0.40)
    static let deepBlue = Color(red: 0.08, green: 0.30, blue: 0.58)
    
    // Subtle Teal Accent
    static let teal = Color(red: 0.04, green: 0.60, blue: 0.64)
    static let tealSoft = Color(red: 0.04, green: 0.60, blue: 0.64).opacity(0.12)
    
    // Semantic Colours
    static let success = Color(red: 0.10, green: 0.65, blue: 0.38)
    static let warning = Color(red: 0.92, green: 0.56, blue: 0.08)
    static let danger = Color(red: 0.85, green: 0.20, blue: 0.24)
    static let info = Color(red: 0.15, green: 0.48, blue: 0.88)
    
    // Adaptive Surfaces (supports Light & Dark mode)
    #if canImport(UIKit)
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let elevatedBackground = Color(.systemBackground)
    #else
    static let background = Color.gray.opacity(0.08)
    static let cardBackground = Color.white
    static let elevatedBackground = Color.white
    #endif
    
    // Gradients
    static let heroGradient = LinearGradient(
        colors: [navy, deepBlue, teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let primaryButtonGradient = LinearGradient(
        colors: [navy, teal],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Spacing tokens
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }
    
    // Corner Radius tokens
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
    }
}

// MARK: - Brand Logo View

struct TechCareLogoView: View {
    var size: CGFloat = 84
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(TCTheme.heroGradient)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.24), lineWidth: 1.5)
                )
                .shadow(color: TCTheme.navy.opacity(0.28), radius: size * 0.14, y: size * 0.07)
            
            ZStack {
                Image(systemName: "cpu.fill")
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(.white)
                
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(TCTheme.teal)
                    .padding(size * 0.06)
                    .background(Circle().fill(Color.white))
                    .offset(x: size * 0.22, y: size * 0.22)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("TechCare Logo")
    }
}

// MARK: - Reusable Button Styles

struct TCPrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    var useTeal: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
            .background(
                Group {
                    if isDisabled {
                        Color.gray.opacity(0.45)
                    } else if useTeal {
                        TCTheme.teal
                    } else {
                        TCTheme.primaryButtonGradient
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: TCTheme.Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.98 : 1.0)
            .shadow(color: isDisabled ? .clear : TCTheme.teal.opacity(0.25), radius: 8, y: 4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct TCSecondaryButtonStyle: ButtonStyle {
    var tint: Color = TCTheme.teal
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: TCTheme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TCTheme.Radius.md, style: .continuous)
                    .strokeBorder(tint.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Reusable Card & Badge Components

struct TCCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TCTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: TCTheme.Radius.lg, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}

struct TCBadge: View {
    let text: String
    var icon: String? = nil
    var color: Color = TCTheme.teal
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption2.weight(.bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }
}

struct TCSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(TCTheme.teal)
                }
            }
        }
    }
}

struct TCFormField<Content: View>: View {
    let label: String
    var required: Bool = false
    var errorMessage: String? = nil
    let content: Content
    
    init(label: String, required: Bool = false, errorMessage: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.required = required
        self.errorMessage = errorMessage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                if required {
                    Text("*")
                        .font(.caption.weight(.bold))
                        .foregroundColor(TCTheme.danger)
                }
            }
            content
            if let errorMessage, !errorMessage.isEmpty {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(TCTheme.danger)
            }
        }
    }
}

struct TCEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TCTheme.tealSoft)
                    .frame(width: 68, height: 68)
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(TCTheme.teal)
            }
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(TCPrimaryButtonStyle(useTeal: true))
                .frame(maxWidth: 240)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - INR Currency Formatter Utility

enum INRFormatter {
    private static let formatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "INR"
        nf.currencySymbol = "₹"
        nf.locale = Locale(identifier: "en_IN")
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        return nf
    }()
    
    static func format(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        return formatter.string(from: number) ?? "₹\(number)"
    }
}
