import SwiftUI

struct VideoEditorView: View {
    @State private var startTime: Double = 0
    @State private var endTime: Double = 30
    @State private var currentTime: Double = 0
    @State private var isPlaying = false
    @Environment(\.dismiss) private var dismiss
    
    private let videoDuration: Double = 60
    
    var body: some View {
        ZStack {
            RuthGradientBackground()
            
            VStack(spacing: 0) {
                // Video preview
                videoPreviewSection
                
                // Timeline scrubber
                timelineSection
                
                // Trim controls
                trimControlsSection
                
                // Action buttons
                actionButtonsSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Video Editor")
                    .font(Font.ruthHeadline())
                    .foregroundColor(.white)
            }
        }
    }
    
    private var videoPreviewSection: some View {
        ZStack {
            // Placeholder video
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.ruthDeepBlue,
                            Color.ruthNavy
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "video.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))
            
            // Play button overlay
            Button {
                HapticFeedback.medium.trigger()
                isPlaying.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            
            VStack {
                Spacer()
                
                // Time display
                GlassCard(opacity: 0.25) {
                    Text("\(formatTime(currentTime)) / \(formatTime(videoDuration))")
                        .font(Font.ruthSubheadline())
                        .foregroundColor(.white)
                        .padding(16)
                }
                .padding(20)
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
    }
    
    private var timelineSection: some View {
        VStack(spacing: 12) {
            Text("Timeline")
                .font(Font.ruthSubheadline())
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Timeline visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background timeline
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                    
                    // Selected range
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.ruthNeonBlue.opacity(0.4),
                                    Color.ruthCyan.opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat((endTime - startTime) / videoDuration) * geometry.size.width)
                        .offset(x: CGFloat(startTime / videoDuration) * geometry.size.width)
                    
                    // Playhead
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                        .offset(x: CGFloat(currentTime / videoDuration) * geometry.size.width)
                    
                    // Start handle
                    TimeHandle(isStart: true)
                        .offset(x: CGFloat(startTime / videoDuration) * geometry.size.width - 10)
                    
                    // End handle
                    TimeHandle(isStart: false)
                        .offset(x: CGFloat(endTime / videoDuration) * geometry.size.width - 10)
                }
                .frame(height: 60)
            }
            .frame(height: 60)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial.opacity(0.2))
    }
    
    private var trimControlsSection: some View {
        VStack(spacing: 16) {
            // Start time
            HStack {
                Text("Start")
                    .font(Font.ruthSubheadline())
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(formatTime(startTime))
                    .font(Font.ruthBody())
                    .foregroundColor(.white)
            }
            
            Slider(value: $startTime, in: 0...(endTime - 1))
                .tint(Color.ruthNeonBlue)
            
            // End time
            HStack {
                Text("End")
                    .font(Font.ruthSubheadline())
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(formatTime(endTime))
                    .font(Font.ruthBody())
                    .foregroundColor(.white)
            }
            
            Slider(value: $endTime, in: (startTime + 1)...videoDuration)
                .tint(Color.ruthCyan)
            
            // Duration display
            HStack {
                Text("Clip Duration")
                    .font(Font.ruthSubheadline())
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(formatTime(endTime - startTime))
                    .font(Font.ruthBody())
                    .foregroundColor(Color.ruthCyan)
            }
        }
        .padding(20)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button {
                HapticFeedback.success.trigger()
                dismiss()
            } label: {
                Label("Create Highlight Reel", systemImage: "sparkles")
                    .font(Font.ruthSubheadline())
            }
            .primaryStyle()
            
            Button {
                HapticFeedback.light.trigger()
                dismiss()
            } label: {
                Text("Cancel")
            }
            .secondaryStyle()
        }
        .padding(20)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Time Handle

struct TimeHandle: View {
    let isStart: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isStart ? "chevron.right" : "chevron.left")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: 20, height: 40)
                .cornerRadius(4)
            
            Image(systemName: isStart ? "chevron.right" : "chevron.left")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationStack {
        VideoEditorView()
    }
}
