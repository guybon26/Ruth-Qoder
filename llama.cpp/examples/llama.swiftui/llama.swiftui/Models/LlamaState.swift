import Foundation

// MARK: - TextCompletionEngine Extension

extension LlamaContext: TextCompletionEngine {
    func complete(prompt: String, maxTokens: Int) async throws -> String {
        // Set the max tokens for this completion
        await set_n_len(Int32(maxTokens))
        
        // Initialize completion with the prompt
        await completion_init(text: prompt)
        
        var result = ""
        
        // Loop until generation is done
        while await !is_done {
            let token = await completion_loop()
            result += token
        }
        
        // Clear the context for next use
        await clear()
        
        return result
    }
}

// MARK: - Model

struct Model: Identifiable {
    var id = UUID()
    var name: String
    var url: String
    var filename: String
    var status: String?
    var downloadProgress: Double = 0.0
    var isDownloading: Bool = false
}

@MainActor
class LlamaState: ObservableObject, FederatedClientDelegate {
    @Published var messageLog = ""
    @Published var cacheCleared = false
    @Published var downloadedModels: [Model] = []
    @Published var undownloadedModels: [Model] = []
    @Published var isLoadingModel = false
    @Published var loadingProgress = ""
    @Published var federatedStatus = "Idle"
    let NS_PER_S = 1_000_000_000.0

    private var llamaContext: LlamaContext?
    let taskRouter = TaskRouter()
    private let remoteLLM = RemoteLLM()
    private let federatedClient: FederatedClient
    
    // AGI Agents
    private var plannerAgent: PlannerAgent?
    private var criticAgent: CriticAgent?
    
    // Sensor integration
    private let sensorBridge = IosSensorBridge()
    @Published var sensorData: String = "No sensor data available"
    private var latestLocation: (lat: Double, lon: Double, alt: Double)?
    private var defaultModelUrl: URL? {
        // First, try to load Phi-3 from the project models directory
        let phi3Path = "/Users/guybonnen/Ruth-Qoder/models/Phi-3-mini-4k-instruct-q4.gguf"
        if FileManager.default.fileExists(atPath: phi3Path) {
            return URL(fileURLWithPath: phi3Path)
        }
        
        // Fallback to bundled model if available
        return Bundle.main.url(forResource: "ggml-model", withExtension: "gguf", subdirectory: "models")
    }

    init() {
        self.federatedClient = FederatedClient()
        
        loadModelsFromDisk()
        loadDefaultModels()
        setupSensors()
        setupFederatedLearning()
        setupMediaTools()
    }
    
    private func setupMediaTools() {
        // Register photo and video editing tools
        PhotoEditorTool.register()
        VideoEffectsTool.register()
        print("✓ Media editing tools registered")
    }
    
    private func setupFederatedLearning() {
        federatedClient.delegate = self
        print("✓ Federated learning client configured")
    }
    
    private func setupSensors() {
        // Setup GPS location callback
        sensorBridge.onLocationData = { [weak self] lat, lon, alt in
            self?.latestLocation = (lat, lon, alt)
            self?.updateSensorData()
        }
        
        // Start location tracking
        sensorBridge.startLocation()
    }
    
    private func updateSensorData() {
        var data = ""
        
        if let location = latestLocation {
            data += "GPS Location:\n"
            data += "  Latitude: \(String(format: "%.6f", location.lat))°\n"
            data += "  Longitude: \(String(format: "%.6f", location.lon))°\n"
            data += "  Altitude: \(String(format: "%.1f", location.alt))m\n"
        }
        
        if data.isEmpty {
            sensorData = "No sensor data available"
        } else {
            sensorData = data
        }
    }

    private func loadModelsFromDisk() {
        do {
            let documentsURL = getDocumentsDirectory()
            let modelURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for modelURL in modelURLs {
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                downloadedModels.append(Model(name: modelName, url: "", filename: modelURL.lastPathComponent, status: "downloaded"))
            }
        } catch {
            print("Error loading models from disk: \(error)")
        }
    }

    private func loadDefaultModels() {
        do {
            try loadModel(modelUrl: defaultModelUrl)
        } catch {
            messageLog += "Error loading default model!\n"
            print("❌ Error loading default model: \(error)")
        }

        // Check project models directory
        let projectModelsPath = "/Users/guybonnen/Ruth-Qoder/models/"
        
        for model in defaultModels {
            var modelFound = false
            
            // Check Documents directory
            let docsFileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
            if FileManager.default.fileExists(atPath: docsFileURL.path) {
                modelFound = true
            }
            
            // Check project models directory
            let projectFileURL = URL(fileURLWithPath: projectModelsPath + model.filename)
            if FileManager.default.fileExists(atPath: projectFileURL.path) {
                modelFound = true
                // Add to downloaded models if not already there
                if !downloadedModels.contains(where: { $0.filename == model.filename }) {
                    var downloadedModel = model
                    downloadedModel.status = "downloaded"
                    downloadedModels.append(downloadedModel)
                    print("✓ Found \(model.filename) in project models directory")
                }
            }
            
            if !modelFound {
                var undownloadedModel = model
                undownloadedModel.status = "download"
                undownloadedModels.append(undownloadedModel)
            }
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    private let defaultModels: [Model] = [
        Model(
            name: "Phi-3 Mini 4K (Q4, 2.4 GiB)",
            url: "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf?download=true",
            filename: "Phi-3-mini-4k-instruct-q4.gguf",
            status: "download"
        ),
        Model(name: "TinyLlama-1.1B (Q4_0, 0.6 GiB)",url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-1T-OpenOrca-GGUF/resolve/main/tinyllama-1.1b-1t-openorca.Q4_0.gguf?download=true",filename: "tinyllama-1.1b-1t-openorca.Q4_0.gguf", status: "download"),
        Model(
            name: "TinyLlama-1.1B Chat (Q8_0, 1.1 GiB)",
            url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q8_0.gguf?download=true",
            filename: "tinyllama-1.1b-chat-v1.0.Q8_0.gguf", status: "download"
        ),

        Model(
            name: "TinyLlama-1.1B (F16, 2.2 GiB)",
            url: "https://huggingface.co/ggml-org/models/resolve/main/tinyllama-1.1b/ggml-model-f16.gguf?download=true",
            filename: "tinyllama-1.1b-f16.gguf", status: "download"
        ),

        Model(
            name: "Phi-2.7B (Q4_0, 1.6 GiB)",
            url: "https://huggingface.co/ggml-org/models/resolve/main/phi-2/ggml-model-q4_0.gguf?download=true",
            filename: "phi-2-q4_0.gguf", status: "download"
        ),

        Model(
            name: "Phi-2.7B (Q8_0, 2.8 GiB)",
            url: "https://huggingface.co/ggml-org/models/resolve/main/phi-2/ggml-model-q8_0.gguf?download=true",
            filename: "phi-2-q8_0.gguf", status: "download"
        ),

        Model(
            name: "Mistral-7B-v0.1 (Q4_0, 3.8 GiB)",
            url: "https://huggingface.co/TheBloke/Mistral-7B-v0.1-GGUF/resolve/main/mistral-7b-v0.1.Q4_0.gguf?download=true",
            filename: "mistral-7b-v0.1.Q4_0.gguf", status: "download"
        ),
        Model(
            name: "OpenHermes-2.5-Mistral-7B (Q3_K_M, 3.52 GiB)",
            url: "https://huggingface.co/TheBloke/OpenHermes-2.5-Mistral-7B-GGUF/resolve/main/openhermes-2.5-mistral-7b.Q3_K_M.gguf?download=true",
            filename: "openhermes-2.5-mistral-7b.Q3_K_M.gguf", status: "download"
        )
    ]
    func loadModel(modelUrl: URL?) throws {
        if let modelUrl {
            isLoadingModel = true
            loadingProgress = "Loading model..."
            messageLog += "Loading model...\n"
            
            llamaContext = try LlamaContext.create_context(path: modelUrl.path())
            
            // Initialize AGI agents with the loaded context
            if let context = llamaContext {
                plannerAgent = PlannerAgent(engine: context)
                criticAgent = CriticAgent(engine: context)
                print("✓ AGI agents initialized (PlannerAgent, CriticAgent)")
            }
            
            isLoadingModel = false
            loadingProgress = ""
            messageLog += "Loaded model \(modelUrl.lastPathComponent)\n"

            // Assuming that the model is successfully loaded, update the downloaded models
            updateDownloadedModels(modelName: modelUrl.lastPathComponent, status: "downloaded")
        } else {
            messageLog += "Load a model from the list below\n"
        }
    }


    private func updateDownloadedModels(modelName: String, status: String) {
        undownloadedModels.removeAll { $0.name == modelName }
    }
    
    // MARK: - Model Download
    
    func downloadModel(_ model: Model) async {
        guard let url = URL(string: model.url) else {
            print("❌ Invalid model URL")
            return
        }
        
        // Update model status to downloading
        if let index = undownloadedModels.firstIndex(where: { $0.id == model.id }) {
            undownloadedModels[index].isDownloading = true
            undownloadedModels[index].downloadProgress = 0.0
        }
        
        let destination = getDocumentsDirectory().appendingPathComponent(model.filename)
        
        do {
            // Create download task with progress tracking
            let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let expectedLength = response.expectedContentLength
            var downloadedData = Data()
            downloadedData.reserveCapacity(Int(expectedLength))
            
            var downloadedBytes: Int64 = 0
            
            for try await byte in asyncBytes {
                downloadedData.append(byte)
                downloadedBytes += 1
                
                // Update progress every 1MB
                if downloadedBytes % (1024 * 1024) == 0 {
                    let progress = Double(downloadedBytes) / Double(expectedLength)
                    await updateDownloadProgress(for: model.id, progress: progress)
                }
            }
            
            // Final progress update
            await updateDownloadProgress(for: model.id, progress: 1.0)
            
            // Write to disk
            try downloadedData.write(to: destination)
            
            // Update model lists
            if let index = undownloadedModels.firstIndex(where: { $0.id == model.id }) {
                var downloadedModel = undownloadedModels[index]
                downloadedModel.status = "downloaded"
                downloadedModel.isDownloading = false
                downloadedModel.downloadProgress = 1.0
                
                undownloadedModels.remove(at: index)
                downloadedModels.append(downloadedModel)
            }
            
            messageLog += "✓ Downloaded \(model.name)\n"
            print("✓ Model downloaded: \(model.filename)")
            
        } catch {
            print("❌ Download failed: \(error.localizedDescription)")
            messageLog += "❌ Download failed: \(model.name) - \(error.localizedDescription)\n"
            
            // Reset download status
            if let index = undownloadedModels.firstIndex(where: { $0.id == model.id }) {
                undownloadedModels[index].isDownloading = false
                undownloadedModels[index].downloadProgress = 0.0
            }
        }
    }
    
    @MainActor
    private func updateDownloadProgress(for modelId: UUID, progress: Double) {
        if let index = undownloadedModels.firstIndex(where: { $0.id == modelId }) {
            undownloadedModels[index].downloadProgress = progress
        }
    }


    func complete(text: String) async {
        // Log query submission
        LocalContextStore.shared.logEvent(.querySubmitted(query: text, timestamp: Date()))
        
        // First, check if message contains a tool intent
        if let toolResult = await ConversationManager.processMessage(text) {
            messageLog += "\n[Tool Execution]\n"
            messageLog += toolResult
            messageLog += "\n\n"
            return
        }
        
        // Determine which model to use
        let modelType = taskRouter.determineModel(for: text)
        let modelName = taskRouter.getModelDescription(for: modelType)
        
        // Get current context and available tools
        let localContext = taskRouter.getCurrentContext()
        let availableTools = taskRouter.getAvailableTools()
        
        // Add sensor context to the message
        var contextualText = text
        if latestLocation != nil {
            let sensorContext = "\n\n[System Context - Current Sensor Data:\n\(sensorData)]"
            contextualText = text + sensorContext
            
            // Log location access
            LocalContextStore.shared.logEvent(.locationAccessed(timestamp: Date()))
        }
        
        // Add local context for more comprehensive information
        contextualText += "\n\n" + localContext.formatForPrompt()
        
        // Add available tools information
        if !availableTools.isEmpty {
            contextualText += "\n[Available Tools]\n"
            for tool in availableTools {
                contextualText += "- \(tool.name): \(tool.description)\n"
            }
        }
        
        messageLog += "[Using: \(modelName)]\n"
        messageLog += "\(text)\n"
        
        switch modelType {
        case .local:
            await completeWithLocalModel(text: contextualText)
        case .remote:
            await completeWithRemoteLLM(text: contextualText)
        }
    }
    
    private func completeWithLocalModel(text: String) async {
        guard let llamaContext else {
            messageLog += "⚠️ Local model not loaded. Please load a model first.\n"
            return
        }
        
        // Set max tokens based on query length (shorter queries = shorter responses)
        let wordCount = text.components(separatedBy: .whitespaces).count
        let maxTokens: Int32 = wordCount <= 10 ? 128 : 256
        await llamaContext.set_n_len(maxTokens)

        let t_start = DispatchTime.now().uptimeNanoseconds
        await llamaContext.completion_init(text: text)
        let t_heat_end = DispatchTime.now().uptimeNanoseconds
        let t_heat = Double(t_heat_end - t_start) / NS_PER_S

        Task.detached {
            while await !llamaContext.is_done {
                let result = await llamaContext.completion_loop()
                await MainActor.run {
                    self.messageLog += "\(result)"
                }
            }

            let t_end = DispatchTime.now().uptimeNanoseconds
            let t_generation = Double(t_end - t_heat_end) / self.NS_PER_S
            let tokens_per_second = Double(await llamaContext.n_len) / t_generation

            await llamaContext.clear()

            await MainActor.run {
                self.messageLog += """
                    \n
                    Done
                    Heat up took \(t_heat)s
                    Generated \(tokens_per_second) t/s\n
                    """
            }
        }
    }
    
    private func completeWithRemoteLLM(text: String) async {
        do {
            let (response, source) = try await remoteLLM.complete(text: text)
            
            let sourceLabel = source == .cloud ? "Cloud LLM" : "Local Model"
            messageLog += response + "\n\n[Response from \(sourceLabel)]\n\n"
        } catch {
            messageLog += "⚠️ Remote LLM error: \(error.localizedDescription)\n"
            messageLog += "Falling back to local model...\n\n"
            await completeWithLocalModel(text: text)
        }
    }

    func bench() async {
        guard let llamaContext else {
            return
        }

        messageLog += "\n"
        messageLog += "Running benchmark...\n"
        messageLog += "Model info: "
        messageLog += await llamaContext.model_info() + "\n"

        let t_start = DispatchTime.now().uptimeNanoseconds
        let _ = await llamaContext.bench(pp: 8, tg: 4, pl: 1) // heat up
        let t_end = DispatchTime.now().uptimeNanoseconds

        let t_heat = Double(t_end - t_start) / NS_PER_S
        messageLog += "Heat up time: \(t_heat) seconds, please wait...\n"

        // if more than 5 seconds, then we're probably running on a slow device
        if t_heat > 5.0 {
            messageLog += "Heat up time is too long, aborting benchmark\n"
            return
        }

        let result = await llamaContext.bench(pp: 512, tg: 128, pl: 1, nr: 3)

        messageLog += "\(result)"
        messageLog += "\n"
    }

    func clear() async {
        guard let llamaContext else {
            return
        }

        await llamaContext.clear()
        messageLog = ""
    }
    
    // MARK: - AGI Agent Methods
    
    /// Handle complex multi-step instructions using Planner and Critic agents
    /// - Parameter instruction: The complex instruction to process
    /// - Returns: Summary of planned and approved steps, or error message
    func handleComplexInstruction(_ instruction: String) async -> String {
        guard let planner = plannerAgent, let critic = criticAgent else {
            return "⚠️ AGI agents not initialized. Please load a model first."
        }
        
        do {
            // Step 1: Plan the instruction into steps
            messageLog += "\n[Planner Agent] Breaking down instruction...\n"
            let steps = try await planner.planSteps(for: instruction)
            
            if steps.isEmpty {
                return "⚠️ Planner could not break down the instruction into steps."
            }
            
            messageLog += "Planned \(steps.count) steps:\n"
            for (index, step) in steps.enumerated() {
                messageLog += "  \(index + 1). \(step)\n"
            }
            
            // Step 2: Evaluate each step with the Critic
            messageLog += "\n[Critic Agent] Evaluating safety of each step...\n"
            var safeSteps: [String] = []
            
            for (index, step) in steps.enumerated() {
                let safe = try await critic.isSafe(actionDescription: step)
                if safe {
                    safeSteps.append(step)
                    messageLog += "  ✓ Step \(index + 1): APPROVED\n"
                } else {
                    messageLog += "  ⚠️ Step \(index + 1): REJECTED (safety concern)\n"
                }
            }
            
            // Step 3: Generate summary
            if safeSteps.isEmpty {
                return "⚠️ All steps were rejected by the safety critic. The instruction may contain unsafe actions."
            }
            
            let summary = safeSteps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            
            messageLog += "\n[Plan Summary] \(safeSteps.count)/\(steps.count) steps approved:\n\(summary)\n\n"
            
            return "📋 Plan generated with \(safeSteps.count) approved steps:\n\n\(summary)"
            
        } catch {
            return "❌ Planning failed: \(error.localizedDescription)"
        }
    }
    
    /// Detect if a prompt requires complex planning
    /// - Parameter text: The user's prompt
    /// - Returns: true if the prompt contains planning keywords
    func isComplexInstruction(_ text: String) -> Bool {
        let lowerText = text.lowercased()
        let planningKeywords = ["plan", "project", "multi-step", "steps to", "how to", "guide", "tutorial", "process"]
        return planningKeywords.contains(where: { lowerText.contains($0) })
    }
    
    // MARK: - Federated Learning
    
    /// Start a federated training round
    func startFederatedTraining() {
        federatedClient.scheduleTrainingRound()
    }
    
    /// Force start training (bypass conditions)
    func forceStartFederatedTraining() {
        federatedClient.forceStartTraining()
    }
    
    /// Get current training conditions
    func getFederatedConditions() -> TrainingConditions {
        return federatedClient.getConditions()
    }
    
    /// Apply adapter weights to local model
    private func applyAdapter(_ adapter: AdapterWeights) {
        // In a real implementation, this would:
        // 1. Validate adapter compatibility
        // 2. Load adapter weights into model
        // 3. Merge with base model if needed
        // 4. Update inference engine
        
        print("🔧 Applying adapter to local model")
        print("   Version: \(adapter.metadata.version)")
        print("   Round: \(adapter.metadata.roundNumber)")
        print("   Size: \(adapter.data.count) bytes")
        print("   Checksum: \(adapter.metadata.checksum ?? "none")")
        
        messageLog += "\n[Federated Learning] Applied adapter v\(adapter.metadata.version) (round \(adapter.metadata.roundNumber))\n"
        
        // Log adapter application
        LocalContextStore.shared.logEvent(
            .toolExecuted(toolName: "apply_adapter", success: true, timestamp: Date())
        )
    }
    
    // MARK: - FederatedClientDelegate
    
    func federatedClient(_ client: FederatedClient, didUpdateStatus status: String) {
        federatedStatus = status
        print("📡 Federated status: \(status)")
    }
    
    func federatedClient(_ client: FederatedClient, didReceiveNewAdapter adapter: AdapterWeights) {
        print("🎁 Received new adapter from federation server")
        applyAdapter(adapter)
    }
}
