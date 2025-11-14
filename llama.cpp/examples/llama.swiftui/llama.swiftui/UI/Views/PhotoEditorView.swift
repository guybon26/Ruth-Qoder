import SwiftUI

struct PhotoEditorView: View {
    @State private var filterIntensity: Double = 0.8
    @State private var selectedFilter: PhotoFilter = .cinematic
    @State private var showUndoAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            RuthGradientBackground()
            
            VStack(spacing: 0) {
                // Photo preview
                photoPreviewSection
                
                // Filter controls
                filterControlsSection
                
                // Action buttons
                actionButtonsSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Photo Editor")
                    .font(Font.ruthHeadline())
                    .foregroundColor(.white)
            }
        }
    }
    
    private var photoPreviewSection: some View {
        ZStack {
            // Placeholder image
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
            
            Image(systemName: "photo.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))
            
            VStack {
                Spacer()
                
                // Filter name overlay
                GlassCard(opacity: 0.25) {
                    HStack {
                        Image(systemName: selectedFilter.icon)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(selectedFilter.rawValue)
                            .font(Font.ruthSubheadline())
                        
                        Spacer()
                        
                        Text("\(Int(filterIntensity * 100))%")
                            .font(Font.ruthCaption())
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .foregroundColor(.white)
                    .padding(16)
                }
                .padding(20)
            }
        }
        .aspectRatio(4/3, contentMode: .fit)
    }
    
    private var filterControlsSection: some View {
        VStack(spacing: 20) {
            // Intensity slider
            VStack(alignment: .leading, spacing: 12) {
                Text("Intensity")
                    .font(Font.ruthSubheadline())
                    .foregroundColor(.white.opacity(0.8))
                
                NeonSlider(value: $filterIntensity)
            }
            .padding(.horizontal, 20)
            
            // Filter selector
            filterSelector
        }
        .padding(.vertical, 24)
        .background(.ultraThinMaterial.opacity(0.2))
    }
    
    private var filterSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PhotoFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        action: {
                            HapticFeedback.light.trigger()
                            withAnimation(.ruthBounce) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button {
                HapticFeedback.medium.trigger()
                showUndoAlert = true
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .secondaryStyle()
            
            Button {
                HapticFeedback.medium.trigger()
            } label: {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .secondaryStyle()
            
            Button {
                HapticFeedback.success.trigger()
                dismiss()
            } label: {
                Label("Save", systemImage: "checkmark")
            }
            .primaryStyle()
        }
        .padding(20)
    }
}

// MARK: - Photo Filter

enum PhotoFilter: String, CaseIterable {
    case sepia = "Sepia"
    case noir = "Noir"
    case vintage = "Vintage"
    case cinematic = "Cinematic"
    case vibrant = "Vibrant"
    case fade = "Fade"
    case cool = "Cool"
    case warm = "Warm"
    case brighten = "Brighten"
    case contrast = "Contrast"
    
    var icon: String {
        switch self {
        case .sepia: return "camera.filters"
        case .noir: return "circle.lefthalf.filled"
        case .vintage: return "photo.fill"
        case .cinematic: return "film.fill"
        case .vibrant: return "sparkles"
        case .fade: return "sun.max.fill"
        case .cool: return "snowflake"
        case .warm: return "flame.fill"
        case .brighten: return "sun.max"
        case .contrast: return "circle.hexagongrid.fill"
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let filter: PhotoFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.ruthNeonBlue.opacity(isSelected ? 0.3 : 0.1),
                                    Color.ruthCyan.opacity(isSelected ? 0.2 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.ruthNeonBlue, lineWidth: 2)
                            .frame(width: 56, height: 56)
                            .blur(radius: 2)
                    }
                    
                    Image(systemName: filter.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                Text(filter.rawValue)
                    .font(Font.ruthCaption())
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
        }
    }
}

// MARK: - Neon Slider

struct NeonSlider: View {
    @Binding var value: Double
    
    var body: some View {
        VStack(spacing: 0) {
            Slider(value: $value, in: 0...1)
                .tint(
                    LinearGradient(
                        colors: [Color.ruthNeonBlue, Color.ruthCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            GlassmorphicBackground(
                opacity: 0.15,
                cornerRadius: 12,
                glowColor: Color.ruthNeonBlue,
                showGlow: true,
                glowIntensity: 0.3
            )
        )
    }
}

#Preview {
    NavigationStack {
        PhotoEditorView()
    }
}
