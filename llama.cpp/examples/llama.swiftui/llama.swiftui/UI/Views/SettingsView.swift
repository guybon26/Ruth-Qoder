import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var llamaState: LlamaState
    @Environment(\.dismiss) private var dismiss
    @State private var showPersonalization = false
    @State private var showPrivacy = false
    @State private var showLearningData = false
    @State private var showInsights = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RuthGradientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Personalization
                        personalizationSection
                        
                        // Privacy
                        privacySection
                        
                        // Learning Data
                        learningDataSection
                        
                        // Model Info
                        modelInfoSection
                        
                        // Federated Learning
                        federatedLearningSection
                        
                        Spacer(minLength: 40)
                    }
                    .ruthSafeArea()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(Font.ruthHeadline())
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticFeedback.light.trigger()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                    .iconStyle()
                }
            }
            .sheet(isPresented: $showInsights) {
                RuthInsightsView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            BreathingRing()
                .scaleEffect(0.8)
            
            Text("Ruth Assistant")
                .font(Font.ruthTitle())
                .foregroundColor(.white)
            
            Text("Loyal to the Truth")
                .font(Font.ruthSubheadline())
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 20)
    }
    
    private var personalizationSection: some View {
        SettingsSection(title: "Personalization") {
            SettingsRow(
                icon: "person.fill",
                title: "User Profile",
                subtitle: "Guy",
                action: { showPersonalization = true }
            )
            
            SettingsRow(
                icon: "sparkles",
                title: "Preferences",
                subtitle: "Learn from my interactions",
                action: { showPersonalization = true }
            )
            
            SettingsRow(
                icon: "brain",
                title: "Behavior Learning",
                subtitle: "Adapt to my style",
                action: { showPersonalization = true }
            )
        }
    }
    
    private var privacySection: some View {
        SettingsSection(title: "Data & Privacy") {
            SettingsRow(
                icon: "lock.shield.fill",
                title: "Privacy Protection",
                subtitle: "On-device only",
                badge: "Active"
            )
            
            SettingsRow(
                icon: "eye.slash.fill",
                title: "Redaction",
                subtitle: "Remove sensitive data",
                badge: "Enabled"
            )
            
            SettingsRow(
                icon: "trash.fill",
                title: "Clear Local Data",
                subtitle: "Delete all stored context",
                action: { showPrivacy = true },
                isDestructive: true
            )
        }
    }
    
    private var learningDataSection: some View {
        SettingsSection(title: "What Ruth Has Learned") {
            SettingsRow(
                icon: "brain.head.profile",
                title: "View Insights",
                subtitle: "See what Ruth knows about you",
                action: { showInsights = true }
            )
            
            LearnedDataRow(
                icon: "photo.fill",
                title: "Photo Preferences",
                value: "Cinematic filters at 80%"
            )
            
            LearnedDataRow(
                icon: "pencil.line",
                title: "Writing Style",
                value: "Professional, concise"
            )
            
            LearnedDataRow(
                icon: "clock.fill",
                title: "Active Hours",
                value: "9 AM - 6 PM"
            )
            
            LearnedDataRow(
                icon: "location.fill",
                title: "Frequent Locations",
                value: "Home, Work, Gym"
            )
        }
    }
    
    private var modelInfoSection: some View {
        SettingsSection(title: "Model Information") {
            InfoRow(label: "Local SLM", value: modelName)
            InfoRow(label: "Model Status", value: llamaState.isLoadingModel ? "Loading..." : "Ready")
            InfoRow(label: "Cloud LLM", value: "Connected")
            InfoRow(label: "Downloaded Models", value: "\(llamaState.downloadedModels.count)")
        }
    }
    
    private var modelName: String {
        if let firstModel = llamaState.downloadedModels.first {
            return firstModel.name
        }
        return "No model loaded"
    }
    
    private var federatedLearningSection: some View {
        SettingsSection(title: "Federated Learning") {
            SettingsRow(
                icon: "antenna.radiowaves.left.and.right",
                title: "FL Status",
                subtitle: llamaState.federatedStatus,
                badge: llamaState.federatedStatus
            )
            
            SettingsRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Conditions",
                subtitle: federatedConditionsText
            )
            
            Button {
                HapticFeedback.medium.trigger()
                llamaState.forceStartFederatedTraining()
            } label: {
                Label("Upload Adapter Now", systemImage: "arrow.up.circle.fill")
                    .font(Font.ruthSubheadline())
            }
            .primaryStyle()
            .padding(.top, 8)
        }
    }
    
    private var federatedConditionsText: String {
        let conditions = llamaState.getFederatedConditions()
        if conditions.isReadyForTraining {
            return "Ready for training"
        } else {
            var reasons: [String] = []
            if !conditions.isOnWiFi { reasons.append("WiFi") }
            if !conditions.isCharging { reasons.append("Charging") }
            if !conditions.hasSufficientData { reasons.append("Data") }
            return "Waiting: " + reasons.joined(separator: ", ")
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(Font.ruthSubheadline())
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 4)
            
            GlassCard(opacity: 0.15) {
                VStack(spacing: 0) {
                    content
                }
                .padding(4)
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let badge: String?
    var action: (() -> Void)?
    var isDestructive: Bool = false
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        action: (() -> Void)? = nil,
        isDestructive: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.action = action
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Button {
            HapticFeedback.light.trigger()
            action?()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .red : Color.ruthNeonBlue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Font.ruthBody())
                        .foregroundColor(isDestructive ? .red : .white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Font.ruthCaption())
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(Font.ruthCaption())
                        .foregroundColor(Color.ruthCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.ruthCyan.opacity(0.2))
                        )
                }
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(16)
        }
        .disabled(action == nil)
    }
}

// MARK: - Learned Data Row

struct LearnedDataRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.ruthCyan)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.ruthBody())
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(Font.ruthCaption())
                    .foregroundColor(Color.ruthCyan)
            }
            
            Spacer()
        }
        .padding(16)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(Font.ruthBody())
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(Font.ruthBody())
                .foregroundColor(.white)
        }
        .padding(16)
    }
}

#Preview {
    SettingsView()
}
