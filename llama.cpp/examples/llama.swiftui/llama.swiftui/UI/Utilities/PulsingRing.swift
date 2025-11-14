import SwiftUI

/// Pulsing ring component for emphasis and life
struct PulsingRing: View {
    var color: Color
    var size: CGFloat
    var lineWidth: CGFloat
    var duration: Double
    
    @State private var isPulsing = false
    
    init(
        color: Color = Color(hex: "4AB8FF"),
        size: CGFloat = 60,
        lineWidth: CGFloat = 3,
        duration: Double = 1.5
    ) {
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.duration = duration
    }
    
    var body: some View {
        ZStack {
            // Inner solid ring
            Circle()
                .stroke(color, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Outer pulsing ring
            Circle()
                .stroke(color.opacity(0.4), lineWidth: lineWidth)
                .frame(width: size, height: size)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0 : 0.8)
        }
        .onAppear {
            withAnimation(
                .easeOut(duration: duration)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

/// Ruth breathing indicator
struct BreathingRing: View {
    @State private var isBreathing = false
    
    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "4AB8FF").opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: isBreathing ? 60 : 40
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 10)
            
            // Main ring
            PulsingRing(size: 50, lineWidth: 2, duration: 2.5)
            
            // Inner dot
            Circle()
                .fill(Color(hex: "A0FFE7"))
                .frame(width: 12, height: 12)
                .shadow(color: Color(hex: "A0FFE7"), radius: 8)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                isBreathing = true
            }
        }
    }
}

/// Activity indicator with multiple pulsing rings
struct ActivityRings: View {
    @State private var pulse1 = false
    @State private var pulse2 = false
    @State private var pulse3 = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "4AB8FF").opacity(0.3), lineWidth: 2)
                .frame(width: 40, height: 40)
                .scaleEffect(pulse1 ? 1.5 : 1.0)
                .opacity(pulse1 ? 0 : 1)
            
            Circle()
                .stroke(Color(hex: "A0FFE7").opacity(0.3), lineWidth: 2)
                .frame(width: 40, height: 40)
                .scaleEffect(pulse2 ? 1.5 : 1.0)
                .opacity(pulse2 ? 0 : 1)
            
            Circle()
                .stroke(Color(hex: "4AB8FF").opacity(0.3), lineWidth: 2)
                .frame(width: 40, height: 40)
                .scaleEffect(pulse3 ? 1.5 : 1.0)
                .opacity(pulse3 ? 0 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulse1 = true
            }
            withAnimation(.easeOut(duration: 1.5).delay(0.5).repeatForever(autoreverses: false)) {
                pulse2 = true
            }
            withAnimation(.easeOut(duration: 1.5).delay(1.0).repeatForever(autoreverses: false)) {
                pulse3 = true
            }
        }
    }
}
