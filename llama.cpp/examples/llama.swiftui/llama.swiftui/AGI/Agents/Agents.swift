import Foundation

// MARK: - TextCompletionEngine Protocol

/// Protocol for any component that can generate text completions
protocol TextCompletionEngine {
    func complete(prompt: String, maxTokens: Int) async throws -> String
}

// MARK: - PlannerAgent

/// Agent that breaks down complex instructions into discrete steps
final class PlannerAgent {
    private let engine: TextCompletionEngine
    
    init(engine: TextCompletionEngine) {
        self.engine = engine
    }
    
    /// Breaks down a complex instruction into 3-7 clear, numbered steps
    /// - Parameter instruction: The user's instruction to plan
    /// - Returns: Array of step descriptions (without numbers)
    func planSteps(for instruction: String) async throws -> [String] {
        let prompt = """
        You are a planner agent. Break the following user instruction into 3-7 clear, numbered steps. 
        Return only the list, one step per line, prefixed by the step number.
        
        Instruction:
        \(instruction)
        """
        
        print("🗓️ Planning steps for instruction...")
        let reply = try await engine.complete(prompt: prompt, maxTokens: 256)
        print("✓ Planner response received (\(reply.count) chars)")
        
        // Parse the numbered list
        let lines = reply.split(separator: "\n")
        let steps = lines.compactMap { line -> String? in
            // Strip leading numbers like "1. ", "2) ", etc.
            let cleaned = line.replacingOccurrences(
                of: #"^\s*\d+[\.\)]\s*"#,
                with: "",
                options: .regularExpression
            )
            let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        
        print("✓ Parsed \(steps.count) steps from planner")
        return steps
    }
}

// MARK: - CriticAgent

/// Agent that evaluates safety and appropriateness of actions
final class CriticAgent {
    private let engine: TextCompletionEngine
    
    init(engine: TextCompletionEngine) {
        self.engine = engine
    }
    
    /// Checks if an action is safe, legal, and aligned with user interests
    /// - Parameter actionDescription: Description of the action to evaluate
    /// - Returns: true if safe, false otherwise
    func isSafe(actionDescription: String) async throws -> Bool {
        let prompt = """
        You are a safety critic. You will be given an action description. 
        Answer only YES or NO depending on whether the action is safe, legal, and aligned with the user's interest.
        
        Action:
        \(actionDescription)
        """
        
        print("🛡️ Evaluating safety of action: \(actionDescription.prefix(50))...")
        let reply = try await engine.complete(prompt: prompt, maxTokens: 8)
        let normalized = reply.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let safe = normalized.contains("YES")
        print(safe ? "✓ Action approved" : "⚠️ Action rejected")
        
        return safe
    }
}
