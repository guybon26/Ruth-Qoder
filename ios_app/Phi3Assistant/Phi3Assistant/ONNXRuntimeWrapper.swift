import Foundation
import onnxruntime_objc

class ONNXRuntimeWrapper {
    private var session: ORTSession?
    private var env: ORTEnv?
    
    init(modelPath: String) throws {
        // Initialize ONNX Runtime environment
        env = try ORTEnv(loggingLevel: .warning)
        
        // Create session options
        let sessionOptions = try ORTSessionOptions()
        
        // Create inference session
        session = try ORTSession(env: env!, modelPath: modelPath, sessionOptions: sessionOptions)
        
        print("✅ ONNX Runtime session created successfully")
    }
    
    func runInference(inputIds: [Int64]) throws -> [Float] {
        guard let session = session else {
            throw ONNXError.sessionNotInitialized
        }
        
        // Prepare input shape [batch_size, sequence_length]
        let batchSize: Int = 1
        let seqLength: Int = inputIds.count
        let shape: [NSNumber] = [NSNumber(value: batchSize), NSNumber(value: seqLength)]
        
        // Create input tensor data
        let inputData = NSMutableData(bytes: inputIds, length: inputIds.count * MemoryLayout<Int64>.size)
        
        // Create ORT value (tensor)
        let inputValue = try ORTValue(
            tensorData: inputData,
            elementType: .int64,
            shape: shape
        )
        
        // Get input names from the model
        let inputNames = try session.inputNames()
        guard let firstInputName = inputNames.first else {
            throw ONNXError.noInputs
        }
        
        // Get output names as Set
        let outputNames = Set(try session.outputNames())
        
        // Run inference
        let outputs = try session.run(
            withInputs: [firstInputName: inputValue],
            outputNames: outputNames,
            runOptions: nil
        )
        
        // Get output tensor
        guard let outputValue = outputs.values.first else {
            throw ONNXError.noOutputs
        }
        
        // Extract float data from output
        let outputData = try outputValue.tensorData() as Data
        let floatArray = outputData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Float] in
            let floatPtr = ptr.bindMemory(to: Float.self)
            return Array(floatPtr)
        }
        
        return floatArray
    }
    
    func getInputNames() throws -> [String] {
        guard let session = session else {
            throw ONNXError.sessionNotInitialized
        }
        return try session.inputNames()
    }
    
    func getOutputNames() throws -> [String] {
        guard let session = session else {
            throw ONNXError.sessionNotInitialized
        }
        return try session.outputNames()
    }
}

enum ONNXError: Error, LocalizedError {
    case sessionNotInitialized
    case modelNotFound
    case noInputs
    case noOutputs
    case inferenceError(String)
    
    var errorDescription: String? {
        switch self {
        case .sessionNotInitialized:
            return "ONNX Runtime session not initialized"
        case .modelNotFound:
            return "Model file not found in bundle"
        case .noInputs:
            return "Model has no inputs"
        case .noOutputs:
            return "Model has no outputs"
        case .inferenceError(let message):
            return "Inference error: \(message)"
        }
    }
}
