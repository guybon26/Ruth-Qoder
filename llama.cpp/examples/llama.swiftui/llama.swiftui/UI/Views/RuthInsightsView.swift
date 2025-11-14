import SwiftUI

struct RuthInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preferenceEngine = PreferenceEngine()
    @State private var showClearConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RuthGradientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Most Used Tools
                        mostUsedToolsSection
                        
                        // Active Hours
                        activeHoursSection
                        
                        // Insights Summary
                        insightsSummarySection
                        
                        // Reset Memory Button
                        resetMemorySection
                        
                        Spacer(minLength: 40)
                    }
                    .ruthSafeArea()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("What Ruth Knows")
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
            .alert("Clear All Memory?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllMemory()
                }
            } message: {
                Text("This will permanently delete all learned preferences and interaction history. This cannot be undone.")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(Color.ruthNeonBlue)
                .shadow(color: Color.ruthNeonBlue.opacity(0.5), radius: 20)
            
            Text("Insights & Preferences")
                .font(Font.ruthTitle())
                .foregroundColor(.white)
            
            Text("What Ruth has learned about you")
                .font(Font.ruthSubheadline())
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 20)
    }
    
    private var mostUsedToolsSection: some View {
        SettingsSection(title: "Most Used Tools") {
            let topTools = preferenceEngine.getTopTools(limit: 5)
            
            if topTools.isEmpty {
                EmptyStateView(
                    icon: "wrench.and.screwdriver",
                    message: "No tool usage data yet"
                )
            } else {
                ForEach(Array(topTools.enumerated()), id: \.offset) { index, tool in
                    ToolUsageRow(
                        rank: index + 1,
                        toolName: tool.toolName,
                        usageCount: tool.totalUses,
                        acceptanceRate: tool.acceptanceRate
                    )
                    
                    if index < topTools.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                }
            }
        }
    }
    
    private var activeHoursSection: some View {
        SettingsSection(title: "Active Hours") {
            let hourlyData = preferenceEngine.getMessagesPerHour()
            let busiestHours = preferenceEngine.getBusiestHours(limit: 3)
            
            if hourlyData.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    message: "No activity data yet"
                )
            } else {
                VStack(spacing: 16) {
                    // Horizontal hour chart
                    HourlyActivityChart(hourlyData: hourlyData, busiestHours: busiestHours)
                    
                    // Busiest hours text
                    if !busiestHours.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(Color.ruthCyan)
                            
                            Text("Most active: ")
                                .font(Font.ruthCaption())
                                .foregroundColor(.white.opacity(0.7))
                            +
                            Text(busiestHours.map { formatHour($0.hour) }.joined(separator: ", "))
                                .font(Font.ruthCaption())
                                .foregroundColor(Color.ruthCyan)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
    
    private var insightsSummarySection: some View {
        SettingsSection(title: "Insights Summary") {
            VStack(alignment: .leading, spacing: 16) {
                let summary = generateInsightsSummary()
                
                Text(summary)
                    .font(Font.ruthBody())
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(6)
            }
            .padding(16)
        }
    }
    
    private var resetMemorySection: some View {
        VStack(spacing: 12) {
            Button {
                HapticFeedback.medium.trigger()
                showClearConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                    Text("Reset All Memory")
                        .font(Font.ruthSubheadline())
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    GlassCard(opacity: 0.15, glowColor: .red.opacity(0.3)) {
                        Color.clear
                    }
                )
            }
            
            Text("Deletes all learned preferences and interaction history")
                .font(Font.ruthCaption())
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateInsightsSummary() -> String {
        let topTools = preferenceEngine.getTopTools(limit: 3)
        let busiestHours = preferenceEngine.getBusiestHours(limit: 2)
        let totalInteractions = LocalContextStore.shared.loadAllEvents().count
        
        var summary = ""
        
        // Total interactions
        if totalInteractions > 0 {
            summary += "I've learned from \(totalInteractions) interactions with you. "
        } else {
            summary += "I'm still learning about you. "
        }
        
        // Top tools
        if !topTools.isEmpty {
            let toolNames = topTools.prefix(2).map { $0.toolName }.joined(separator: " and ")
            summary += "You use \(toolNames) most frequently. "
        }
        
        // Active hours
        if !busiestHours.isEmpty {
            let hours = busiestHours.map { formatHour($0.hour) }.joined(separator: " and ")
            summary += "You're most active around \(hours). "
        }
        
        // Personalization note
        if totalInteractions >= 10 {
            summary += "I'm using these patterns to better assist you."
        } else if totalInteractions > 0 {
            summary += "Keep using Ruth to help me learn your preferences better."
        } else {
            summary += "Start using Ruth to help me learn your preferences."
        }
        
        return summary
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        
        var components = DateComponents()
        components.hour = hour
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date).lowercased()
        }
        
        return "\(hour):00"
    }
    
    private func clearAllMemory() {
        do {
            try LocalContextStore.shared.clearAllEvents()
            preferenceEngine.refreshPreferences()
            HapticFeedback.success.trigger()
        } catch {
            print("❌ Failed to clear memory: \(error.localizedDescription)")
            HapticFeedback.error.trigger()
        }
    }
}

// MARK: - Tool Usage Row

struct ToolUsageRow: View {
    let rank: Int
    let toolName: String
    let usageCount: Int
    let acceptanceRate: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            Text("\(rank)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(rankColor.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(toolName)
                    .font(Font.ruthBody())
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("\(usageCount) uses")
                        .font(Font.ruthCaption())
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("\(Int(acceptanceRate * 100))% success")
                        .font(Font.ruthCaption())
                        .foregroundColor(Color.ruthCyan)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color.ruthNeonBlue
        case 2: return Color.ruthCyan
        default: return .white.opacity(0.7)
        }
    }
}

// MARK: - Hourly Activity Chart

struct HourlyActivityChart: View {
    let hourlyData: [(hour: Int, count: Int)]
    let busiestHours: [(hour: Int, count: Int)]
    
    private let maxBarHeight: CGFloat = 60
    
    var body: some View {
        let maxCount = hourlyData.map(\.count).max() ?? 1
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<24, id: \.self) { hour in
                    let count = hourlyData.first(where: { $0.hour == hour })?.count ?? 0
                    let isBusiest = busiestHours.contains(where: { $0.hour == hour })
                    
                    VStack(spacing: 4) {
                        // Bar
                        Rectangle()
                            .fill(isBusiest ? Color.ruthNeonBlue : Color.ruthCyan.opacity(0.5))
                            .frame(width: 20, height: calculateBarHeight(count: count, max: maxCount))
                            .cornerRadius(4)
                        
                        // Hour label
                        Text(formatHourShort(hour))
                            .font(.system(size: 10))
                            .foregroundColor(isBusiest ? Color.ruthNeonBlue : .white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func calculateBarHeight(count: Int, max maxValue: Int) -> CGFloat {
        guard maxValue > 0 else { return 4 }
        let ratio = CGFloat(count) / CGFloat(maxValue)
        return Swift.max(4, ratio * maxBarHeight)
    }
    
    private func formatHourShort(_ hour: Int) -> String {
        if hour == 0 {
            return "12a"
        } else if hour < 12 {
            return "\(hour)a"
        } else if hour == 12 {
            return "12p"
        } else {
            return "\(hour - 12)p"
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            
            Text(message)
                .font(Font.ruthBody())
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    RuthInsightsView()
}
