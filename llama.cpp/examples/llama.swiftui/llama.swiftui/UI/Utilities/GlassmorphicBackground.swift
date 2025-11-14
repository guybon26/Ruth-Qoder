import SwiftUI

/// Glassmorphic background component with blur, opacity, and neon glow
struct GlassmorphicBackground: View {
    var opacity: Double = 0.15
    var blurRadius: CGFloat = 20
    var cornerRadius: CGFloat = 20
    var glowColor: Color = Color(hex: "4AB8FF")
    var showGlow: Bool = true
    var glowIntensity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Base glass layer
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .opacity(opacity)
            
            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Neon glow edge
            if showGlow {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                glowColor.opacity(glowIntensity),
                                glowColor.opacity(glowIntensity * 0.5),
                                glowColor.opacity(glowIntensity * 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .blur(radius: 2)
            }
        }
    }
}

/// Glassmorphic card variant with shadow
struct GlassCard: View {
    var opacity: Double = 0.2
    var cornerRadius: CGFloat = 16
    var glowColor: Color = Color(hex: "4AB8FF")
    var content: () -> AnyView
    
    init(
        opacity: Double = 0.2,
        cornerRadius: CGFloat = 16,
        glowColor: Color = Color(hex: "4AB8FF"),
        @ViewBuilder content: @escaping () -> some View
    ) {
        self.opacity = opacity
        self.cornerRadius = cornerRadius
        self.glowColor = glowColor
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        ZStack {
            GlassmorphicBackground(
                opacity: opacity,
                cornerRadius: cornerRadius,
                glowColor: glowColor
            )
            
            content()
        }
        .shadow(color: glowColor.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

/// Deep navy gradient background for Ruth
struct RuthGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "0A0F2D"),
                Color(hex: "0E1A45"),
                Color(hex: "0A0F2D")
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}
