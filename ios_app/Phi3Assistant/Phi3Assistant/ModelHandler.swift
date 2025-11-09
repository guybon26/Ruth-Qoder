import Foundation

class ModelHandler: ObservableObject {
    private var onnxWrapper: ONNXRuntimeWrapper?
    private var tokenizer: Tokenizer?
    private var textGenerator: TextGenerator?
    private var modelReady = false
    
    init() {
        NSLog("✅ ModelHandler init started")
        tokenizer = Tokenizer()
        loadModel()
        NSLog("✅ ModelHandler init completed. Model ready: \(modelReady)")
    }
    
    private func loadModel() {
        do {
            NSLog("📂 Bundle path: \(Bundle.main.bundlePath)")
            
            // List all files in bundle to debug
            if let bundleContents = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath) {
                let onnxFiles = bundleContents.filter { $0.contains("onnx") }
                NSLog("📋 ONNX files in bundle: \(onnxFiles)")
            }
            
            // Try different methods to find the model
            var modelPath: String?
            
            // Method 1: Using Bundle.main.path
            modelPath = Bundle.main.path(forResource: "Phi-3-mini-4k-instruct-q4", ofType: "onnx")
            if modelPath == nil {
                NSLog("⚠️ Method 1 failed: Bundle.main.path returned nil")
                
                // Method 2: Direct path in bundle
                let directPath = Bundle.main.bundlePath + "/Phi-3-mini-4k-instruct-q4.onnx"
                if FileManager.default.fileExists(atPath: directPath) {
                    modelPath = directPath
                    NSLog("✅ Method 2 succeeded: Found at \(directPath)")
                } else {
                    NSLog("⚠️ Method 2 failed: File doesn't exist at \(directPath)")
                }
            } else {
                NSLog("✅ Method 1 succeeded: Found at \(modelPath!)")
            }
            
            guard let finalModelPath = modelPath else {
                NSLog("❌ Model file not found in bundle")
                NSLog("Searched for: Phi-3-mini-4k-instruct-q4.onnx")
                modelReady = false
                return
            }
            
            NSLog("📦 Model found at: \(finalModelPath)")
            let fileSize = try! FileManager.default.attributesOfItem(atPath: finalModelPath)[.size] as! UInt64
            NSLog("📊 Model size: \(fileSize / 1_000_000) MB")
            
            // Initialize ONNX Runtime wrapper
            onnxWrapper = try ONNXRuntimeWrapper(modelPath: finalModelPath)
            
            // Initialize text generator
            if let wrapper = onnxWrapper, let tok = tokenizer {
                textGenerator = TextGenerator(onnxWrapper: wrapper, tokenizer: tok)
            }
            
            // Print model info
            if let wrapper = onnxWrapper {
                NSLog("✅ Model loaded successfully!")
                NSLog("📝 Input names: \(try! wrapper.getInputNames())")
                NSLog("📝 Output names: \(try! wrapper.getOutputNames())")
                modelReady = true
            }
        } catch {
            NSLog("❌ Error loading model: \(error)")
            modelReady = false
        }
    }
    
    func processQuery(_ query: String) -> String {
        guard modelReady, let wrapper = onnxWrapper, let tok = tokenizer else {
            return "⚠️ Model not loaded. Please check if model files are in the bundle."
        }
        
        NSLog("🔄 Processing query: \(query)")
        
        // Use exact token sequence from transformers tokenizer
        // Format: <|system|>You are a helpful assistant.<|end|><|user|>{query}<|end|><|assistant|>
        
        let systemToken: Int64 = 32006  // <|system|>
        let userToken: Int64 = 32010     // <|user|>
        let assistantToken: Int64 = 32001  // <|assistant|>
        let endToken: Int64 = 32007      // <|end|>
        
        // Fixed tokens for "You are a helpful assistant."
        // From: tokenizer.encode("You are a helpful assistant.") = [887, 526, 263, 8444, 20255, 29889]
        let systemMsgTokens: [Int64] = [887, 526, 263, 8444, 20255, 29889]
        
        // Encode user query (using simplified encoder)
        var userTokens = tok.encode(query).map { Int64($0) }
        
        NSLog("📝 User query encoded to \(userTokens.count) tokens: \(userTokens)")
        
        // Build prompt: <|system|>...tokens...<|end|><|user|>...tokens...<|end|><|assistant|>
        var inputTokens: [Int64] = [systemToken]
        inputTokens += systemMsgTokens
        inputTokens += [endToken, userToken]
        inputTokens += userTokens
        inputTokens += [endToken, assistantToken]
        
        NSLog("🎯 Full input: \(inputTokens.count) tokens")
        NSLog("📊 Breakdown: system=\(systemMsgTokens.count), user=\(userTokens.count), special=5")
        
        // Iterative generation parameters
        let maxNewTokens = 100
        let temperature: Float = 0.7
        var generatedTokenIds: [Int] = []
        var generatedText = ""
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generation loop
        for step in 0..<maxNewTokens {
            do {
                // Run inference
                let logits = try wrapper.runInference(inputIds: inputTokens)
                
                // Get logits for last position
                let vocabSize = 32064
                let lastLogits = Array(logits.suffix(vocabSize))
                
                // Sample next token (with temperature)
                let nextTokenId = sampleToken(logits: lastLogits, temperature: temperature)
                
                // Check for end token
                if nextTokenId == Int(endToken) {
                    NSLog("✅ Generated <|end|> token at step \(step)")
                    break
                }
                
                // Decode and append
                let tokenText = tok.decode([nextTokenId])
                generatedText += tokenText
                generatedTokenIds.append(nextTokenId)
                
                // Append to input for next iteration
                inputTokens.append(Int64(nextTokenId))
                
                if step % 10 == 0 {
                    NSLog("Step \(step): Token [\(nextTokenId)] = \"\(tokenText)\"")
                }
                
            } catch {
                NSLog("❌ Error at step \(step): \(error)")
                break
            }
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let tokensPerSecond = generatedTokenIds.count > 0 ? Float(generatedTokenIds.count) / Float(totalTime) : 0
        
        NSLog("✅ Generation complete!")
        NSLog("📊 Stats: \(generatedTokenIds.count) tokens in \(String(format: "%.2f", totalTime))s")
        NSLog("⚡ Speed: \(String(format: "%.1f", tokensPerSecond)) tok/s")
        
        let response = """
        ✅ Phi-3 Mini
        
        Q: \(query)
        
        A: \(generatedText)
        
        ---
        ⚡ \(generatedTokenIds.count) tokens · \(String(format: "%.2f", totalTime))s · \(String(format: "%.1f", tokensPerSecond)) tok/s
        📱 100% on-device
        """
        
        return response
    }
    
    private func sampleToken(logits: [Float], temperature: Float) -> Int {
        // Apply temperature scaling
        let scaledLogits = logits.map { $0 / temperature }
        
        // Apply softmax to get probabilities
        let maxLogit = scaledLogits.max() ?? 0
        let expLogits = scaledLogits.map { exp($0 - maxLogit) }
        let sumExp = expLogits.reduce(0, +)
        let probabilities = expLogits.map { $0 / sumExp }
        
        // Find top token (greedy sampling for now)
        if let maxIndex = probabilities.enumerated().max(by: { $0.element < $1.element })?.offset {
            return maxIndex
        }
        
        return 0 // fallback to <unk>
    }
    
    func isModelLoaded() -> Bool {
        return modelReady
    }
}