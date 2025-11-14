import Foundation

/// Tool schema defining a callable function with input validation
struct ToolSchema {
    let name: String
    let description: String
    let inputSchema: String  // JSON schema describing expected inputs
    let handler: (Any) async throws -> Any
}

/// Errors that can occur during tool execution
enum RuthToolError: Error {
    case toolNotFound(String)
    case invalidInput(String)
    case executionFailed(String)
    case schemaValidationFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .toolNotFound(let name):
            return "Tool '\(name)' not found in registry"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .executionFailed(let message):
            return "Tool execution failed: \(message)"
        case .schemaValidationFailed(let message):
            return "Schema validation failed: \(message)"
        }
    }
}

/// Singleton registry for managing available tools
class ToolRegistry {
    static let shared = ToolRegistry()
    
    private var registry: [String: ToolSchema] = [:]
    
    private init() {
        registerBuiltInTools()
    }
    
    /// Register a new tool in the registry
    func register(_ tool: ToolSchema) {
        registry[tool.name] = tool
        print("✓ Registered tool: \(tool.name)")
    }
    
    /// Get a tool by name
    func get(_ name: String) -> ToolSchema? {
        return registry[name]
    }
    
    /// Get all registered tool names
    func getAllToolNames() -> [String] {
        return Array(registry.keys).sorted()
    }
    
    /// Get all registered tools
    func getAllTools() -> [ToolSchema] {
        return Array(registry.values)
    }
    
    /// Execute a tool by name with given input
    func execute(_ name: String, input: Any) async throws -> Any {
        guard let tool = get(name) else {
            throw RuthToolError.toolNotFound(name)
        }
        
        do {
            return try await tool.handler(input)
        } catch {
            throw RuthToolError.executionFailed(error.localizedDescription)
        }
    }
    
    /// Register built-in tools
    private func registerBuiltInTools() {
        // Photo edit tool (stub)
        register(ToolSchema(
            name: "photo_edit",
            description: "Stub photo edit tool - applies filters, adjustments, and effects to images",
            inputSchema: "{\"type\":\"object\",\"properties\":{\"payload\":{\"type\":\"string\"}}}",
            handler: { input in
                let payload = (input as? [String: Any])?["payload"] as? String ?? "unknown"
                print("🖼️ [Tool photo_edit] payload:", payload)
                return "Photo edit invoked with payload: \(payload)"
            }
        ))
        
        // Video highlight tool (stub)
        register(ToolSchema(
            name: "video_highlight",
            description: "Stub video highlight tool - creates highlight reels from video content",
            inputSchema: "{\"type\":\"object\",\"properties\":{\"payload\":{\"type\":\"string\"}}}",
            handler: { input in
                let payload = (input as? [String: Any])?["payload"] as? String ?? "unknown"
                print("🎬 [Tool video_highlight] payload:", payload)
                return "Video highlight invoked with payload: \(payload)"
            }
        ))
        
        // Text rewrite tool (stub)
        register(ToolSchema(
            name: "text_rewrite",
            description: "Stub text rewrite tool - rewrites text with different styles or improvements",
            inputSchema: "{\"type\":\"object\",\"properties\":{\"payload\":{\"type\":\"string\"}}}",
            handler: { input in
                let payload = (input as? [String: Any])?["payload"] as? String ?? "unknown"
                print("✍️ [Tool text_rewrite] payload:", payload)
                return "Rewritten: \(payload)"
            }
        ))
        
        // Get current time tool
        register(ToolSchema(
            name: "get_current_time",
            description: "Returns the current date and time",
            inputSchema: "{}",
            handler: { _ in
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                return formatter.string(from: Date())
            }
        ))
        
        // Get location tool
        register(ToolSchema(
            name: "get_location",
            description: "Returns the current GPS location (latitude, longitude, altitude)",
            inputSchema: "{}",
            handler: { _ in
                // This will be populated by sensor data
                return ["status": "available", "source": "LocationService"]
            }
        ))
        
        // Get motion state tool
        register(ToolSchema(
            name: "get_motion_state",
            description: "Returns the current motion/activity state (stationary, walking, driving)",
            inputSchema: "{}",
            handler: { _ in
                // This will be populated by sensor data
                return ["status": "available", "source": "MotionService"]
            }
        ))
        
        // Calculate tool
        register(ToolSchema(
            name: "calculate",
            description: "Performs basic arithmetic calculations",
            inputSchema: "{\"type\":\"object\",\"properties\":{\"expression\":{\"type\":\"string\"}},\"required\":[\"expression\"]}",
            handler: { input in
                guard let dict = input as? [String: Any],
                      let expression = dict["expression"] as? String else {
                    throw RuthToolError.invalidInput("Expected dictionary with 'expression' key")
                }
                
                // Simple expression evaluation (for demo purposes)
                let nsExpression = NSExpression(format: expression)
                if let result = nsExpression.expressionValue(with: nil, context: nil) {
                    return result
                } else {
                    throw RuthToolError.executionFailed("Could not evaluate expression")
                }
            }
        ))
    }
}
