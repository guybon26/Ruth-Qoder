import Foundation

// MARK: - Preference Scores

struct ToolPreference {
    let toolName: String
    let acceptanceRate: Double
    let totalUses: Int
    let lastUsed: Date?
}

struct QuietHourPreference {
    let hour: Int
    let rejectionProbability: Double
    let sampleSize: Int
}

// MARK: - Preference Engine

class PreferenceEngine {
    private let contextStore: LocalContextStore
    private var toolAcceptanceRates: [String: Double] = [:]
    private var quietHours: [Int: Double] = [:]
    
    // Additional computed preferences
    private var toolUsageCounts: [String: (accepted: Int, total: Int)] = [:]
    private var hourlyInteractionCounts: [Int: (accepted: Int, total: Int)] = [:]
    
    init(contextStore: LocalContextStore = .shared) {
        self.contextStore = contextStore
        computePreferences()
        print("✓ PreferenceEngine initialized")
    }
    
    // MARK: - Public API
    
    /// Score a tool at a specific date/time
    /// Returns a value between 0.0 (avoid) and 1.0 (prefer)
    func scoreTool(_ name: String, at date: Date = Date()) -> Double {
        var score = 0.5 // Baseline score
        
        // Factor 1: Tool acceptance rate (weight: 0.4)
        if let acceptanceRate = toolAcceptanceRates[name] {
            score = score * 0.6 + acceptanceRate * 0.4
        }
        
        // Factor 2: Quiet hours penalty (weight: 0.3)
        let hour = Calendar.current.component(.hour, from: date)
        if let quietProbability = quietHours[hour] {
            // Higher quiet probability = lower score
            let quietPenalty = quietProbability * 0.3
            score = score * (1.0 - quietPenalty)
        }
        
        // Factor 3: Recency bonus (weight: 0.1)
        if let lastUsed = getLastUsedDate(for: name) {
            let daysSinceUse = Calendar.current.dateComponents([.day], from: lastUsed, to: date).day ?? 0
            let recencyBonus = max(0, 1.0 - Double(daysSinceUse) / 30.0) * 0.1
            score = score + recencyBonus
        }
        
        // Factor 4: Usage frequency bonus (weight: 0.2)
        if let usage = toolUsageCounts[name] {
            let frequencyBonus = min(1.0, Double(usage.total) / 10.0) * 0.2
            score = score * 0.8 + frequencyBonus
        }
        
        return max(0.0, min(1.0, score))
    }
    
    /// Rank multiple tools by preference score
    func rankTools(_ toolNames: [String], at date: Date = Date()) -> [(name: String, score: Double)] {
        return toolNames
            .map { (name: $0, score: scoreTool($0, at: date)) }
            .sorted { $0.score > $1.score }
    }
    
    /// Get the most preferred tool from a list
    func selectBestTool(from toolNames: [String], at date: Date = Date()) -> String? {
        return rankTools(toolNames, at: date).first?.name
    }
    
    /// Get acceptance rate for a tool
    func getAcceptanceRate(for tool: String) -> Double? {
        return toolAcceptanceRates[tool]
    }
    
    /// Get quiet hours data
    func getQuietHours() -> [QuietHourPreference] {
        return quietHours.map { hour, probability in
            let count = hourlyInteractionCounts[hour]?.total ?? 0
            return QuietHourPreference(hour: hour, rejectionProbability: probability, sampleSize: count)
        }.sorted { $0.hour < $1.hour }
    }
    
    /// Get all tool preferences
    func getAllToolPreferences() -> [ToolPreference] {
        return toolAcceptanceRates.map { toolName, rate in
            let usage = toolUsageCounts[toolName] ?? (0, 0)
            let lastUsed = getLastUsedDate(for: toolName)
            return ToolPreference(
                toolName: toolName,
                acceptanceRate: rate,
                totalUses: usage.total,
                lastUsed: lastUsed
            )
        }.sorted { $0.acceptanceRate > $1.acceptanceRate }
    }
    
    /// Refresh preferences from latest events
    func refreshPreferences() {
        computePreferences()
        print("✓ Preferences refreshed")
    }
    
    // MARK: - Private Methods
    
    private func computePreferences() {
        let events = contextStore.loadAllEvents()
        
        // Reset counters
        toolUsageCounts.removeAll()
        hourlyInteractionCounts.removeAll()
        
        // Process events
        for event in events {
            processEventForToolPreferences(event)
            processEventForQuietHours(event)
        }
        
        // Compute acceptance rates
        computeToolAcceptanceRates()
        computeQuietHourProbabilities()
    }
    
    private func processEventForToolPreferences(_ event: ContextEvent) {
        guard let toolName = event.toolName else { return }
        
        var counts = toolUsageCounts[toolName] ?? (accepted: 0, total: 0)
        
        switch event {
        case .suggestionAccepted:
            counts.accepted += 1
            counts.total += 1
        case .suggestionRejected:
            counts.total += 1
        case .toolExecuted(_, let success, _):
            if success {
                counts.accepted += 1
            }
            counts.total += 1
        default:
            break
        }
        
        toolUsageCounts[toolName] = counts
    }
    
    private func processEventForQuietHours(_ event: ContextEvent) {
        let hour = Calendar.current.component(.hour, from: event.timestamp)
        var counts = hourlyInteractionCounts[hour] ?? (accepted: 0, total: 0)
        
        switch event {
        case .message:
            // Count all messages as accepted interactions
            counts.accepted += 1
            counts.total += 1
        case .suggestionAccepted:
            counts.accepted += 1
            counts.total += 1
        case .suggestionRejected:
            counts.total += 1
        case .querySubmitted:
            counts.accepted += 1
            counts.total += 1
        default:
            // Count all events as interactions
            counts.total += 1
        }
        
        hourlyInteractionCounts[hour] = counts
    }
    
    private func computeToolAcceptanceRates() {
        for (toolName, counts) in toolUsageCounts {
            guard counts.total > 0 else { continue }
            let rate = Double(counts.accepted) / Double(counts.total)
            toolAcceptanceRates[toolName] = rate
        }
    }
    
    private func computeQuietHourProbabilities() {
        for (hour, counts) in hourlyInteractionCounts {
            guard counts.total > 0 else { continue }
            
            // Calculate rejection probability
            let rejections = counts.total - counts.accepted
            let rejectionRate = Double(rejections) / Double(counts.total)
            
            // Only mark as quiet hour if we have enough samples and high rejection rate
            if counts.total >= 3 && rejectionRate > 0.5 {
                quietHours[hour] = rejectionRate
            }
        }
    }
    
    private func getLastUsedDate(for toolName: String) -> Date? {
        let events = contextStore.loadAllEvents()
        
        return events
            .filter { $0.toolName == toolName }
            .map { $0.timestamp }
            .max()
    }
    
    // MARK: - Debug Helpers
    
    func printPreferences() {
        print("\n=== Tool Acceptance Rates ===")
        for (tool, rate) in toolAcceptanceRates.sorted(by: { $0.key < $1.key }) {
            let usage = toolUsageCounts[tool] ?? (0, 0)
            print("  \(tool): \(String(format: "%.1f%%", rate * 100)) (\(usage.accepted)/\(usage.total))")
        }
        
        print("\n=== Quiet Hours ===")
        for (hour, probability) in quietHours.sorted(by: { $0.key < $1.key }) {
            let count = hourlyInteractionCounts[hour]?.total ?? 0
            print("  \(hour):00 - Rejection probability: \(String(format: "%.1f%%", probability * 100)) (\(count) samples)")
        }
        
        if toolAcceptanceRates.isEmpty && quietHours.isEmpty {
            print("  No preference data yet")
        }
        print()
    }
}
