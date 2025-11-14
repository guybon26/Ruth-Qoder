import SwiftUI

/// Animated neon glow modifier
struct NeonGlowModifier: ViewModifier {
    var color: Color
    var intensity: Double
    var lineWidth: CGFloat
    var animate: Bool
    
    @State private var pulseIntensity: Double = 1.0
    
    init(
        color: Color = Color(hex: "4AB8FF"),
        intensity: Double = 0.8,
        lineWidth: CGFloat = 2,
        animate: Bool = true
    ) {
        self.color = color
        self.intensity = intensity
        self.lineWidth = lineWidth
        self.animate = animate
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: lineWidth)
                    .blur(radius: animate ? pulseIntensity * 4 : 4)
                    .opacity(intensity * (animate ? pulseIntensity : 1.0))
            )
            .shadow(color: color.opacity(intensity * 0.6), radius: 10, x: 0, y: 0)
            .onAppear {
                if animate {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        pulseIntensity = 0.6
                    }
                }
            }
    }
}

extension View {
    func neonGlow(
        color: Color = Color(hex: "4AB8FF"),
        intensity: Double = 0.8,
        lineWidth: CGFloat = 2,
        animate: Bool = true
    ) -> some View {
        modifier(NeonGlowModifier(
            color: color,
            intensity: intensity,
            lineWidth: lineWidth,
            animate: animate
        ))
    }
}

/// Specific glow presets
extension View {
    func neonBlueGlow(animate: Bool = true) -> some View {
        neonGlow(color: Color(hex: "4AB8FF"), animate: animate)
    }
    
    func neonCyanGlow(animate: Bool = true) -> some View {
        neonGlow(color: Color(hex: "A0FFE7"), animate: animate)
    }
    
    func activeGlow() -> some View {
        neonGlow(color: Color(hex: "4AB8FF"), intensity: 1.0, animate: true)
    }
}
