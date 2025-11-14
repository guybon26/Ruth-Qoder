import Foundation
import UIKit
import Network

// MARK: - Adapter Weights

/// Represents low-rank adapter weights for federated learning (FedLoRA style)
struct AdapterWeights: Codable {
    let data: Data
    let metadata: AdapterMetadata
    
    struct AdapterMetadata: Codable {
        let version: String
        let timestamp: Date
        let deviceId: String
        let roundNumber: Int
        let dataSize: Int
        let checksum: String?
        
        init(version: String = "1.0",
             timestamp: Date = Date(),
             deviceId: String = UUID().uuidString,
             roundNumber: Int = 0,
             dataSize: Int,
             checksum: String? = nil) {
            self.version = version
            self.timestamp = timestamp
            self.deviceId = deviceId
            self.roundNumber = roundNumber
            self.dataSize = dataSize
            self.checksum = checksum
        }
    }
    
    init(data: Data, version: String = "1.0", roundNumber: Int = 0) {
        self.data = data
        self.metadata = AdapterMetadata(
            version: version,
            roundNumber: roundNumber,
            dataSize: data.count,
            checksum: AdapterWeights.calculateChecksum(data)
        )
    }
    
    /// Calculate simple checksum for integrity verification
    private static func calculateChecksum(_ data: Data) -> String {
        let hash = data.reduce(0) { $0 ^ $1 }
        return String(format: "%02x", hash)
    }
    
    /// Generate fake adapter weights for testing
    static func generateFake(size: Int = 1024, roundNumber: Int = 0) -> AdapterWeights {
        var randomData = Data(count: size)
        _ = randomData.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return Int(0) }
            return Int(SecRandomCopyBytes(kSecRandomDefault, size, baseAddress))
        }
        
        return AdapterWeights(data: randomData, roundNumber: roundNumber)
    }
}

// MARK: - Federated Client Delegate

protocol FederatedClientDelegate: AnyObject {
    func federatedClient(_ client: FederatedClient, didUpdateStatus status: String)
    func federatedClient(_ client: FederatedClient, didReceiveNewAdapter adapter: AdapterWeights)
}

// MARK: - Training Conditions

struct TrainingConditions {
    var isOnWiFi: Bool = false
    var isCharging: Bool = false
    var batteryLevel: Float = 0.0
    var hasSufficientData: Bool = false
    
    var isReadyForTraining: Bool {
        return isOnWiFi && isCharging && batteryLevel > 0.2 && hasSufficientData
    }
}

// MARK: - Federated Client Errors

enum FederatedClientError: Error, LocalizedError {
    case notConnected
    case invalidServerURL
    case networkError(Error)
    case serverError(statusCode: Int, message: String)
    case encodingError(Error)
    case decodingError(Error)
    case insufficientData
    case conditionsNotMet(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to network"
        case .invalidServerURL:
            return "Invalid federation server URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .encodingError(let error):
            return "Failed to encode adapter: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode adapter: \(error.localizedDescription)"
        case .insufficientData:
            return "Insufficient local data for training"
        case .conditionsNotMet(let reason):
            return "Training conditions not met: \(reason)"
        }
    }
}

// MARK: - Federated Client

class FederatedClient {
    weak var delegate: FederatedClientDelegate?
    
    private let federationServerURL: String
    private let session: URLSession
    private let contextStore: LocalContextStore
    private let networkMonitor: NWPathMonitor
    
    private var currentConditions = TrainingConditions()
    private var currentRoundNumber = 0
    private var isTrainingInProgress = false
    
    // Minimum number of events required for training
    private let minimumEventsRequired = 10
    
    /// Initialize federated client
    /// - Parameters:
    ///   - serverURL: Federation server endpoint (e.g., "https://federation.example.com/api")
    ///   - contextStore: Local context store for training data
    init(serverURL: String = "https://federation.ruthassistant.example.com/api",
         contextStore: LocalContextStore = .shared) {
        self.federationServerURL = serverURL
        self.contextStore = contextStore
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.allowsCellularAccess = false  // Federated learning only on WiFi
        self.session = URLSession(configuration: config)
        
        self.networkMonitor = NWPathMonitor()
        
        setupNetworkMonitoring()
        updateDeviceConditions()
        
        print("✓ FederatedClient initialized")
        print("  Server: \(serverURL)")
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Public API
    
    /// Schedule a training round if conditions are met
    func scheduleTrainingRound() {
        updateDeviceConditions()
        
        guard !isTrainingInProgress else {
            notifyStatus("Training already in progress")
            return
        }
        
        guard currentConditions.isReadyForTraining else {
            let reasons = getUnmetConditions()
            notifyStatus("Cannot start training: \(reasons.joined(separator: ", "))")
            return
        }
        
        notifyStatus("Starting federated training round \(currentRoundNumber + 1)")
        
        Task {
            await performTrainingRound()
        }
    }
    
    /// Force start training (bypass condition checks - for testing)
    func forceStartTraining() {
        notifyStatus("Force starting training round \(currentRoundNumber + 1)")
        
        Task {
            await performTrainingRound()
        }
    }
    
    /// Get current training conditions
    func getConditions() -> TrainingConditions {
        updateDeviceConditions()
        return currentConditions
    }
    
    // MARK: - Training Round Logic
    
    private func performTrainingRound() async {
        isTrainingInProgress = true
        defer { isTrainingInProgress = false }
        
        do {
            // Step 1: Load local interaction data
            notifyStatus("Loading local interaction data...")
            let localData = loadLocalTrainingData()
            
            guard localData.eventCount >= minimumEventsRequired else {
                throw FederatedClientError.insufficientData
            }
            
            notifyStatus("Loaded \(localData.eventCount) events for training")
            
            // Step 2: Simulate local training and produce adapter
            notifyStatus("Training local adapter...")
            let localAdapter = try await trainLocalAdapter(with: localData)
            
            notifyStatus("Local adapter trained (\(localAdapter.data.count) bytes)")
            
            // Step 2.5: Generate ZK proof for privacy
            notifyStatus("Generating zero-knowledge proof...")
            let zkProof = await ZKProofEngine.generateProof(for: localAdapter)
            
            notifyStatus("ZK proof generated (\(zkProof.proofData.count) bytes, type: \(zkProof.proofType.rawValue))")
            
            // Step 3: Send adapter to federation server
            notifyStatus("Uploading adapter to federation server...")
            let serverAdapter = try await uploadAdapter(localAdapter, withProof: zkProof)
            
            notifyStatus("Received updated adapter from server (\(serverAdapter.data.count) bytes)")
            
            // Step 4: Notify delegate of new adapter
            currentRoundNumber += 1
            delegate?.federatedClient(self, didReceiveNewAdapter: serverAdapter)
            
            notifyStatus("Training round \(currentRoundNumber) completed successfully")
            
            // Log training event
            LocalContextStore.shared.logEvent(
                .toolExecuted(toolName: "federated_training", success: true, timestamp: Date())
            )
            
        } catch {
            notifyStatus("Training round failed: \(error.localizedDescription)")
            print("❌ Federated training error: \(error)")
            
            // Log failure
            LocalContextStore.shared.logEvent(
                .toolExecuted(toolName: "federated_training", success: false, timestamp: Date())
            )
        }
    }
    
    // MARK: - Local Training Data
    
    private struct LocalTrainingData {
        let eventCount: Int
        let acceptedSuggestions: Int
        let rejectedSuggestions: Int
        let toolExecutions: Int
        let queryCount: Int
    }
    
    private func loadLocalTrainingData() -> LocalTrainingData {
        let events = contextStore.loadAllEvents()
        
        var data = LocalTrainingData(
            eventCount: events.count,
            acceptedSuggestions: 0,
            rejectedSuggestions: 0,
            toolExecutions: 0,
            queryCount: 0
        )
        
        for event in events {
            switch event {
            case .suggestionAccepted:
                data = LocalTrainingData(
                    eventCount: data.eventCount,
                    acceptedSuggestions: data.acceptedSuggestions + 1,
                    rejectedSuggestions: data.rejectedSuggestions,
                    toolExecutions: data.toolExecutions,
                    queryCount: data.queryCount
                )
            case .suggestionRejected:
                data = LocalTrainingData(
                    eventCount: data.eventCount,
                    acceptedSuggestions: data.acceptedSuggestions,
                    rejectedSuggestions: data.rejectedSuggestions + 1,
                    toolExecutions: data.toolExecutions,
                    queryCount: data.queryCount
                )
            case .toolExecuted:
                data = LocalTrainingData(
                    eventCount: data.eventCount,
                    acceptedSuggestions: data.acceptedSuggestions,
                    rejectedSuggestions: data.rejectedSuggestions,
                    toolExecutions: data.toolExecutions + 1,
                    queryCount: data.queryCount
                )
            case .querySubmitted:
                data = LocalTrainingData(
                    eventCount: data.eventCount,
                    acceptedSuggestions: data.acceptedSuggestions,
                    rejectedSuggestions: data.rejectedSuggestions,
                    toolExecutions: data.toolExecutions,
                    queryCount: data.queryCount + 1
                )
            default:
                break
            }
        }
        
        return data
    }
    
    // MARK: - Local Adapter Training (Stubbed)
    
    private func trainLocalAdapter(with data: LocalTrainingData) async throws -> AdapterWeights {
        // Simulate training time
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Generate fake adapter weights
        // In a real implementation, this would:
        // 1. Load base model
        // 2. Apply LoRA training on local data
        // 3. Extract adapter weights
        let adapterSize = 4096 // 4KB adapter (realistic for LoRA)
        let adapter = AdapterWeights.generateFake(size: adapterSize, roundNumber: currentRoundNumber)
        
        print("🎯 Generated local adapter: \(adapter.data.count) bytes")
        return adapter
    }
    
    // MARK: - Server Communication
    
    private func uploadAdapter(_ adapter: AdapterWeights, withProof proof: ZKProof) async throws -> AdapterWeights {
        guard let url = URL(string: "\(federationServerURL)/federated/update") else {
            throw FederatedClientError.invalidServerURL
        }
        
        // For now, simulate server communication
        // In production, this would make a real HTTP POST with ZK proof
        return try await simulateServerCommunication(adapter, proof: proof)
    }
    
    private func simulateServerCommunication(_ localAdapter: AdapterWeights, proof: ZKProof) async throws -> AdapterWeights {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Verify ZK proof before processing
        let isProofValid = await ZKProofEngine.verifyProof(proof)
        guard isProofValid else {
            throw FederatedClientError.serverError(statusCode: 400, message: "Invalid ZK proof")
        }
        
        // Simulate server aggregating adapters and returning updated global adapter
        print("📡 Simulated server communication")
        print("   Sent: \(localAdapter.data.count) bytes")
        print("   ZK Proof verified: \(proof.proofType.rawValue)")
        
        let serverAdapter = AdapterWeights.generateFake(
            size: localAdapter.data.count,
            roundNumber: currentRoundNumber + 1
        )
        
        print("   Received: \(serverAdapter.data.count) bytes")
        
        return serverAdapter
    }
    
    // Real HTTP implementation (disabled for now)
    private func uploadAdapterToServer(_ adapter: AdapterWeights) async throws -> AdapterWeights {
        guard let url = URL(string: "\(federationServerURL)/federated/update") else {
            throw FederatedClientError.invalidServerURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode adapter
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(adapter)
        } catch {
            throw FederatedClientError.encodingError(error)
        }
        
        // Send request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FederatedClientError.networkError(URLError(.badServerResponse))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw FederatedClientError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let serverAdapter = try decoder.decode(AdapterWeights.self, from: data)
            return serverAdapter
        } catch {
            throw FederatedClientError.decodingError(error)
        }
    }
    
    // MARK: - Device Conditions
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.currentConditions.isOnWiFi = path.usesInterfaceType(.wifi)
            self?.updateDeviceConditions()
        }
        
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }
    
    private func updateDeviceConditions() {
        // Update WiFi status (handled by network monitor)
        
        // Check charging status
        UIDevice.current.isBatteryMonitoringEnabled = true
        currentConditions.isCharging = UIDevice.current.batteryState == .charging || 
                                       UIDevice.current.batteryState == .full
        currentConditions.batteryLevel = UIDevice.current.batteryLevel
        
        // Check if we have sufficient data
        let eventCount = contextStore.loadAllEvents().count
        currentConditions.hasSufficientData = eventCount >= minimumEventsRequired
    }
    
    private func getUnmetConditions() -> [String] {
        var reasons: [String] = []
        
        if !currentConditions.isOnWiFi {
            reasons.append("Not on WiFi")
        }
        if !currentConditions.isCharging {
            reasons.append("Not charging")
        }
        if currentConditions.batteryLevel < 0.2 {
            reasons.append("Low battery (\(Int(currentConditions.batteryLevel * 100))%)")
        }
        if !currentConditions.hasSufficientData {
            let eventCount = contextStore.loadAllEvents().count
            reasons.append("Insufficient data (\(eventCount)/\(minimumEventsRequired) events)")
        }
        
        return reasons
    }
    
    // MARK: - Helper Methods
    
    private func notifyStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.federatedClient(self, didUpdateStatus: status)
        }
    }
}
