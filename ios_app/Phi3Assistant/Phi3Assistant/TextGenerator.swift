import Foundation

class TextGenerator {
    private let onnxWrapper: ONNXRuntimeWrapper
    private let tokenizer: Tokenizer
    
    // Generation parameters
    struct GenerationConfig {
        var maxNewTokens: Int = 100
        var temperature: Float = 0.7
        var topK: Int = 50
        var topP: Float = 0.9
        var repetitionPenalty: Float = 1.1
    }
    
    init(onnxWrapper: ONNXRuntimeWrapper, tokenizer: Tokenizer) {
        self.onnxWrapper = onnxWrapper
        self.tokenizer = tokenizer
    }
    
    func generate(prompt: String, config: GenerationConfig = GenerationConfig()) -> String {
        // Encode the prompt
        var inputIds = tokenizer.encode(prompt)
        let eosToken = tokenizer.getEOSToken()
        var generatedTokens: [Int] = []
        
        print("🔄 Starting generation...")
        print("📝 Prompt tokens: \(inputIds.count)")
        
        // Generation loop
        for step in 0..<config.maxNewTokens {
            // Convert to Int64 for ONNX
            let int64Ids = inputIds.map { Int64($0) }
            
            // Run inference
            guard let logits = try? onnxWrapper.runInference(inputIds: int64Ids) else {
                print("❌ Inference failed at step \(step)")
                break
            }
            
            // Get logits for the last token position
            // Assuming output shape is [batch_size, seq_len, vocab_size]
            let vocabSize = logits.count / inputIds.count
            let lastTokenLogits = Array(logits.suffix(vocabSize))
            
            // Sample next token
            let nextToken = sampleToken(
                from: lastTokenLogits,
                temperature: config.temperature,
                topK: config.topK,
                topP: config.topP,
                generatedTokens: generatedTokens,
                repetitionPenalty: config.repetitionPenalty
            )
            
            // Check for end of sequence
            if nextToken == eosToken {
                print("✅ Generation completed (EOS token)")
                break
            }
            
            // Add to generated tokens
            generatedTokens.append(nextToken)
            inputIds.append(nextToken)
            
            // Print progress every 10 tokens
            if (step + 1) % 10 == 0 {
                print("📊 Generated \(step + 1) tokens...")
            }
        }
        
        print("✅ Generation finished. Total tokens: \(generatedTokens.count)")
        
        // Decode generated tokens
        let generatedText = tokenizer.decode(generatedTokens)
        return generatedText
    }
    
    private func sampleToken(
        from logits: [Float],
        temperature: Float,
        topK: Int,
        topP: Float,
        generatedTokens: [Int],
        repetitionPenalty: Float
    ) -> Int {
        var adjustedLogits = logits
        
        // Apply repetition penalty
        if repetitionPenalty != 1.0 {
            for token in generatedTokens {
                if token < adjustedLogits.count {
                    adjustedLogits[token] /= repetitionPenalty
                }
            }
        }
        
        // Apply temperature
        if temperature != 1.0 {
            adjustedLogits = adjustedLogits.map { $0 / temperature }
        }
        
        // Apply softmax
        let expLogits = adjustedLogits.map { exp($0) }
        let sumExp = expLogits.reduce(0, +)
        let probabilities = expLogits.map { $0 / sumExp }
        
        // Top-K filtering
        var topKIndices = probabilities.enumerated()
            .sorted { $0.element > $1.element }
            .prefix(topK)
            .map { $0.offset }
        
        // Top-P (nucleus) filtering
        var cumulativeProb: Float = 0.0
        var topPIndices: [Int] = []
        
        for index in topKIndices {
            cumulativeProb += probabilities[index]
            topPIndices.append(index)
            if cumulativeProb >= topP {
                break
            }
        }
        
        // Sample from filtered distribution
        if topPIndices.isEmpty {
            topPIndices = [topKIndices.first!]
        }
        
        let filteredProbs = topPIndices.map { probabilities[$0] }
        let sumFiltered = filteredProbs.reduce(0, +)
        let normalizedProbs = filteredProbs.map { $0 / sumFiltered }
        
        // Sample using cumulative distribution
        let randomValue = Float.random(in: 0..<1)
        var cumulative: Float = 0.0
        
        for (i, prob) in normalizedProbs.enumerated() {
            cumulative += prob
            if randomValue <= cumulative {
                return topPIndices[i]
            }
        }
        
        // Fallback: return token with highest probability
        return topPIndices[0]
    }
    
    // Greedy decoding (simpler alternative)
    func generateGreedy(prompt: String, maxTokens: Int = 50) -> String {
        var inputIds = tokenizer.encode(prompt)
        let eosToken = tokenizer.getEOSToken()
        var generatedTokens: [Int] = []
        
        for _ in 0..<maxTokens {
            let int64Ids = inputIds.map { Int64($0) }
            
            guard let logits = try? onnxWrapper.runInference(inputIds: int64Ids) else {
                break
            }
            
            // Get last token logits
            let vocabSize = logits.count / inputIds.count
            let lastTokenLogits = Array(logits.suffix(vocabSize))
            
            // Get token with highest probability (greedy)
            if let maxIndex = lastTokenLogits.enumerated().max(by: { $0.element < $1.element })?.offset {
                if maxIndex == eosToken {
                    break
                }
                generatedTokens.append(maxIndex)
                inputIds.append(maxIndex)
            } else {
                break
            }
        }
        
        return tokenizer.decode(generatedTokens)
    }
}
