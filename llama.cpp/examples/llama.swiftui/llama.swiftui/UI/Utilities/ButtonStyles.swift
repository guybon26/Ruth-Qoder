import SwiftUI

/// Primary neon button style
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    GlassmorphicBackground(
                        opacity: 0.25,
                        cornerRadius: 16,
                        glowColor: Color(hex: "4AB8FF"),
                        showGlow: true,
                        glowIntensity: isEnabled ? 0.8 : 0.3
                    )
                    
                    if isEnabled {
                        LinearGradient(
                            colors: [
                                Color(hex: "4AB8FF").opacity(0.3),
                                Color(hex: "A0FFE7").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(16)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Secondary button style (glass only)
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(Color(hex: "A0FFE7"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                GlassmorphicBackground(
                    opacity: 0.15,
                    cornerRadius: 14,
                    glowColor: Color(hex: "A0FFE7"),
                    showGlow: true,
                    glowIntensity: 0.4
                )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Icon button style (circular)
struct IconButtonStyle: ButtonStyle {
    var glowColor: Color = Color(hex: "4AB8FF")
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                    
                    Circle()
                        .strokeBorder(
                            glowColor.opacity(0.6),
                            lineWidth: 1.5
                        )
                        .blur(radius: 2)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Action tile button style (for home screen)
struct ActionTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Send button style (for chat input)
struct SendButtonStyle: ButtonStyle {
    var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isEnabled ? [
                                    Color(hex: "4AB8FF"),
                                    Color(hex: "A0FFE7")
                                ] : [
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    if isEnabled {
                        Circle()
                            .stroke(Color(hex: "4AB8FF"), lineWidth: 2)
                            .blur(radius: 4)
                            .opacity(0.6)
                    }
                }
            )
            .scaleEffect(configuration.isPressed && isEnabled ? 0.85 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension Button {
    func primaryStyle(enabled: Bool = true) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isEnabled: enabled))
    }
    
    func secondaryStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func iconStyle(glowColor: Color = Color(hex: "4AB8FF")) -> some View {
        self.buttonStyle(IconButtonStyle(glowColor: glowColor))
    }
    
    func actionTileStyle() -> some View {
        self.buttonStyle(ActionTileStyle())
    }
    
    func sendStyle(enabled: Bool) -> some View {
        self.buttonStyle(SendButtonStyle(isEnabled: enabled))
    }
}
