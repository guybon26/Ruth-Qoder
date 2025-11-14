import SwiftUI

/// Floating animation modifier for playful UI elements
struct FloatingAnimationModifier: ViewModifier {
    var amplitude: CGFloat
    var duration: Double
    var delay: Double
    
    @State private var isFloating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : amplitude)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isFloating.toggle()
                }
            }
    }
}

extension View {
    func floating(
        amplitude: CGFloat = 10,
        duration: Double = 2.0,
        delay: Double = 0
    ) -> some View {
        modifier(FloatingAnimationModifier(
            amplitude: amplitude,
            duration: duration,
            delay: delay
        ))
    }
}

/// Bounce animation on tap
struct BounceAnimationModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
    
    func onPress() {
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }
    }
}

extension View {
    func bounceOnTap(action: @escaping () -> Void) -> some View {
        modifier(BounceAnimationModifier())
            .onTapGesture {
                action()
            }
    }
}

/// Shimmer effect for loading states
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
