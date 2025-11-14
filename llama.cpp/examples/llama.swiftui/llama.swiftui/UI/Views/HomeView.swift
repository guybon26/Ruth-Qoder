import SwiftUI

struct HomeView: View {
    @EnvironmentObject var llamaState: LlamaState
    @State private var promptText = ""
    @State private var showSettings = false
    @State private var showModelSelector = false
    @State private var selectedAction: ActionType? = nil
    @State private var userPrompt: String? = nil
    
    let userName = "Guy"
    
    var body: some View {
        NavigationStack {
            ZStack {
                RuthGradientBackground()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        HeaderView(showSettings: $showSettings, showModelSelector: $showModelSelector)
                        
                        // Greeting
                        GreetingView(userName: userName)
                            .floating(amplitude: 8, duration: 3.0)
                        
                        // Prompt Input
                        PromptInputBar(text: $promptText, onSend: handlePromptSubmit)
                        
                        // Action Tiles
                        ActionTilesGrid(selectedAction: $selectedAction)
                        
                        // Smart Suggestions
                        SmartSuggestionsSection()
                        
                        // Sensor Data (if available)
                        if llamaState.sensorData != "No sensor data available" {
                            SensorDataSection(sensorData: llamaState.sensorData)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .ruthSafeArea()
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedAction != nil },
                set: { 
                    if !$0 { 
                        selectedAction = nil
                        userPrompt = nil // Clear the prompt when navigating back
                    }
                }
            )) {
                destinationView(for: selectedAction)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showModelSelector) {
                ModelSelectorView()
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for action: ActionType?) -> some View {
        switch action {
        case .editPhotos:
            PhotoEditorView()
        case .createVideo:
            VideoEditorView()
        case .writeSomething:
            ChatView(initialPrompt: userPrompt ?? "Help me write something")
        case .summarizeFiles:
            ChatView(initialPrompt: "Summarize my recent files")
        case .none:
            EmptyView()
        }
    }
    
    private func handlePromptSubmit() {
        guard !promptText.isEmpty else { return }
        
        HapticFeedback.medium.trigger()
        
        // Store the user's prompt and navigate to chat
        userPrompt = promptText
        selectedAction = .writeSomething
        promptText = ""
    }
}

// MARK: - Header View

struct HeaderView: View {
    @Binding var showSettings: Bool
    @Binding var showModelSelector: Bool
    
    var body: some View {
        HStack {
            Text("Ruth.")
                .font(Font.ruthTitle())
                .foregroundColor(.white)
                .shadow(color: Color.ruthNeonBlue.opacity(0.5), radius: 10, x: 0, y: 0)
            
            Spacer()
            
            // Model selector button
            Button {
                HapticFeedback.light.trigger()
                showModelSelector = true
            } label: {
                Image(systemName: "cpu")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .iconStyle(glowColor: Color.ruthCyan)
            
            // Settings button
            Button {
                HapticFeedback.light.trigger()
                showSettings = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .iconStyle()
        }
    }
}

// MARK: - Greeting View

struct GreetingView: View {
    let userName: String
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(greeting), \(userName) 👋")
                .font(Font.ruthHeadline())
                .foregroundColor(.white)
            
            Text("What are we doing today?")
                .font(Font.ruthSubheadline())
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Prompt Input Bar

struct PromptInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Voice button placeholder
            Button {
                HapticFeedback.light.trigger()
            } label: {
                Image(systemName: "waveform")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .iconStyle(glowColor: Color.ruthCyan)
            
            // Text field
            TextField("Ask Ruth anything...", text: $text)
                .font(Font.ruthBody())
                .foregroundColor(.white)
                .focused($isFocused)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    ZStack {
                        GlassmorphicBackground(
                            opacity: 0.2,
                            cornerRadius: 16,
                            glowColor: isFocused ? Color.ruthNeonBlue : Color.white,
                            showGlow: true,
                            glowIntensity: isFocused ? 0.8 : 0.2
                        )
                    }
                )
            
            // Send button
            Button {
                onSend()
            } label: {
                Image(systemName: "arrow.up")
            }
            .sendStyle(enabled: !text.isEmpty)
            .disabled(text.isEmpty)
        }
    }
}

// MARK: - Action Type

enum ActionType {
    case editPhotos
    case createVideo
    case writeSomething
    case summarizeFiles
}

// MARK: - Action Tiles Grid

struct ActionTilesGrid: View {
    @Binding var selectedAction: ActionType?
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ActionTile(
                icon: "photo.stack",
                title: "Edit Photos",
                color: Color.ruthNeonBlue,
                action: { selectedAction = .editPhotos }
            )
            
            ActionTile(
                icon: "video.badge.plus",
                title: "Create Video",
                color: Color.ruthCyan,
                action: { selectedAction = .createVideo }
            )
            
            ActionTile(
                icon: "square.and.pencil",
                title: "Write Something",
                color: Color(hex: "A0FFE7"),
                action: { selectedAction = .writeSomething }
            )
            
            ActionTile(
                icon: "doc.text.magnifyingglass",
                title: "Summarize Files",
                color: Color(hex: "4AB8FF"),
                action: { selectedAction = .summarizeFiles }
            )
        }
    }
}

// MARK: - Action Tile

struct ActionTile: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button {
            HapticFeedback.medium.trigger()
            action()
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    PulsingRing(color: color, size: 50, lineWidth: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(Font.ruthSubheadline())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                GlassmorphicBackground(
                    opacity: 0.2,
                    cornerRadius: 20,
                    glowColor: color,
                    showGlow: true,
                    glowIntensity: 0.6
                )
            )
        }
        .actionTileStyle()
    }
}

// MARK: - Smart Suggestions Section

struct SmartSuggestionsSection: View {
    let suggestions = [
        "You usually write your day summary now.",
        "You took 14 photos at lunch — make a highlight reel?",
        "Want to organize today's screenshots?"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Suggestions")
                .font(Font.ruthSubheadline())
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions.indices, id: \.self) { index in
                        SuggestionCard(text: suggestions[index])
                            .floating(amplitude: 5, duration: 2.5, delay: Double(index) * 0.3)
                    }
                }
            }
        }
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let text: String
    
    var body: some View {
        Button {
            HapticFeedback.light.trigger()
        } label: {
            Text(text)
                .font(Font.ruthBody())
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(width: 280)
                .background(
                    ZStack {
                        GlassmorphicBackground(
                            opacity: 0.2,
                            cornerRadius: 16,
                            glowColor: Color.ruthNeonBlue,
                            showGlow: true,
                            glowIntensity: 0.4
                        )
                        
                        // Pulsing accent ring
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.ruthNeonBlue.opacity(0.3), lineWidth: 1)
                            .blur(radius: 2)
                    }
                )
        }
    }
}

// MARK: - Sensor Data Section

struct SensorDataSection: View {
    let sensorData: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.ruthCyan)
                
                Text("Live Sensor Data")
                    .font(Font.ruthCaption())
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 4)
            
            GlassCard(opacity: 0.15) {
                Text(sensorData)
                    .font(Font.ruthCaption())
                    .foregroundColor(Color.ruthCyan)
                    .padding(16)
            }
        }
    }
}

#Preview {
    HomeView()
}
