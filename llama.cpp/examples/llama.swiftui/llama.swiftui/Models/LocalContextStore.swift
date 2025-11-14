import Foundation
import CryptoKit
import Security

// MARK: - Context Events

enum ContextEvent: Codable, Equatable {
    case message(role: String, text: String, timestamp: Date)
    case suggestionAccepted(toolName: String, timestamp: Date)
    case suggestionRejected(toolName: String, timestamp: Date)
    case photoEdited(assetId: String, timestamp: Date)
    case videoEdited(assetId: String, timestamp: Date)
    case textEdited(timestamp: Date)
    case toolExecuted(toolName: String, success: Bool, timestamp: Date)
    case querySubmitted(query: String, timestamp: Date)
    case locationAccessed(timestamp: Date)
    case motionDetected(state: String, timestamp: Date)
    
    var timestamp: Date {
        switch self {
        case .message(_, _, let ts),
             .suggestionAccepted(_, let ts),
             .suggestionRejected(_, let ts),
             .photoEdited(_, let ts),
             .videoEdited(_, let ts),
             .textEdited(let ts),
             .toolExecuted(_, _, let ts),
             .querySubmitted(_, let ts),
             .locationAccessed(let ts),
             .motionDetected(_, let ts):
            return ts
        }
    }
    
    var toolName: String? {
        switch self {
        case .suggestionAccepted(let name, _),
             .suggestionRejected(let name, _),
             .toolExecuted(let name, _, _):
            return name
        default:
            return nil
        }
    }
}

// MARK: - Keychain Helper

private class KeychainHelper {
    static let shared = KeychainHelper()
    private let service = "com.ruthassistant.contextstore"
    private let account = "encryption_key"
    
    func getOrCreateKey() throws -> SymmetricKey {
        // Try to load existing key
        if let keyData = try? loadKey() {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key
        let key = SymmetricKey(size: .bits256)
        try saveKey(key)
        return key
    }
    
    private func saveKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing key first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [
                NSLocalizedDescriptionKey: "Failed to save encryption key to Keychain"
            ])
        }
    }
    
    private func loadKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [
                NSLocalizedDescriptionKey: "Failed to load encryption key from Keychain"
            ])
        }
        
        return keyData
    }
}

// MARK: - Local Context Store

class LocalContextStore {
    static let shared = LocalContextStore()
    
    private let fileName = "ruth_context.json"
    private let encryptionKey: SymmetricKey
    private var events: [ContextEvent] = []
    private let fileManager = FileManager.default
    
    private var fileURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private init() {
        // Initialize encryption key first
        if let key = try? KeychainHelper.shared.getOrCreateKey() {
            self.encryptionKey = key
        } else {
            // Fallback to temporary key if Keychain fails
            self.encryptionKey = SymmetricKey(size: .bits256)
            print("⚠️ LocalContextStore initialized with temporary key")
        }
        
        // Then load events
        do {
            try loadEvents()
            print("✓ LocalContextStore initialized with \(events.count) events")
        } catch {
            print("⚠️ Failed to load events: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public API
    
    /// Log a new context event
    func logEvent(_ event: ContextEvent) {
        events.append(event)
        
        // Save asynchronously to avoid blocking
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                try self?.saveEvents()
            } catch {
                print("⚠️ Failed to save event: \(error.localizedDescription)")
            }
        }
        
        print("✓ Logged event: \(event)")
    }
    
    /// Load all stored events
    func loadAllEvents() -> [ContextEvent] {
        return events
    }
    
    /// Get events filtered by type
    func getEvents(ofType filter: (ContextEvent) -> Bool) -> [ContextEvent] {
        return events.filter(filter)
    }
    
    /// Get events within a time range
    func getEvents(from startDate: Date, to endDate: Date) -> [ContextEvent] {
        return events.filter { event in
            event.timestamp >= startDate && event.timestamp <= endDate
        }
    }
    
    /// Clear all events (use with caution)
    func clearAllEvents() throws {
        events.removeAll()
        try fileManager.removeItem(at: fileURL)
        print("✓ All events cleared")
    }
    
    // MARK: - Private Methods
    
    private func loadEvents() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            // No file yet, start with empty events
            events = []
            return
        }
        
        // Read encrypted data
        let encryptedData = try Data(contentsOf: fileURL)
        
        // Decrypt
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
        
        // Decode JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        events = try decoder.decode([ContextEvent].self, from: decryptedData)
    }
    
    private func saveEvents() throws {
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(events)
        
        // Encrypt
        let sealedBox = try AES.GCM.seal(jsonData, using: encryptionKey)
        guard let encryptedData = sealedBox.combined else {
            throw NSError(domain: "LocalContextStore", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to combine encrypted data"
            ])
        }
        
        // Write to file atomically
        try encryptedData.write(to: fileURL, options: .atomic)
    }
}
