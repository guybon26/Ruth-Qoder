import SwiftUI

// MARK: - Color Extensions

extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Ruth brand colors
    static let ruthNavy = Color(hex: "0A0F2D")
    static let ruthDeepBlue = Color(hex: "0E1A45")
    static let ruthNeonBlue = Color(hex: "4AB8FF")
    static let ruthCyan = Color(hex: "A0FFE7")
}

// MARK: - View Extensions

extension View {
    /// Apply Ruth gradient background
    func ruthBackground() -> some View {
        self.background(RuthGradientBackground())
    }
    
    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Font Extensions

extension Font {
    static func ruthTitle() -> Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }
    
    static func ruthHeadline() -> Font {
        .system(size: 22, weight: .semibold, design: .rounded)
    }
    
    static func ruthSubheadline() -> Font {
        .system(size: 17, weight: .medium, design: .rounded)
    }
    
    static func ruthBody() -> Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }
    
    static func ruthCaption() -> Font {
        .system(size: 13, weight: .regular, design: .rounded)
    }
}

// MARK: - Animation Extensions

extension Animation {
    static var ruthSpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    }
    
    static var ruthBounce: Animation {
        .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)
    }
    
    static var ruthSmooth: Animation {
        .easeInOut(duration: 0.3)
    }
}

// MARK: - Shape Extensions

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Edge Insets Extensions

extension EdgeInsets {
    static var ruthDefault: EdgeInsets {
        EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
    }
    
    static var ruthLarge: EdgeInsets {
        EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
    }
    
    static var ruthSmall: EdgeInsets {
        EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    
    func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

extension View {
    func hapticTap(_ style: HapticFeedback = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                style.trigger()
            }
        )
    }
}

// MARK: - Safe Area Extensions

extension View {
    func ruthSafeArea() -> some View {
        self.padding(.horizontal, 20)
            .padding(.top, 16)
    }
}
