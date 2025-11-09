import Foundation
import OnnxRuntime

class ModelDebugger {
    static func printModelInfo(modelPath: String) {
        do {
            let env = try ORTEnv(loggingLevel: ORTLoggingLevel.verbose)
            let session = try ORTSession(env: env, modelPath: modelPath)
            
            print("=== Model Information ===")
            print("Model path: \(modelPath)")
            
            // Print input information
            let inputNames = try session.inputNames()
            print("Input names: \(inputNames)")
            
            for inputName in inputNames {
                if let inputInfo = try session.inputInfo(for: inputName) {
                    print("Input '\(inputName)':")
                    print("  Type: \(inputInfo.type)")
                    print("  Shape: \(inputInfo.shape)")
                }
            }
            
            // Print output information
            let outputNames = try session.outputNames()
            print("Output names: \(outputNames)")
            
            for outputName in outputNames {
                if let outputInfo = try session.outputInfo(for: outputName) {
                    print("Output '\(outputName)':")
                    print("  Type: \(outputInfo.type)")
                    print("  Shape: \(outputInfo.shape)")
                }
            }
            
        } catch {
            print("Error getting model info: \(error)")
        }
    }
    
    static func testInputTensor(inputIds: [Int32], shape: [Int64]) {
        do {
            print("=== Testing Input Tensor ===")
            print("Input IDs count: \(inputIds.count)")
            print("Shape: \(shape)")
            
            let inputData = Data(bytes: inputIds, count: inputIds.count * MemoryLayout<Int32>.size)
            let tensor = try ORTTensor(data: inputData, shape: shape, dataType: ORTTensorDataType.int32)
            
            print("Tensor created successfully")
            print("Tensor data type: \(tensor.dataType)")
            print("Tensor shape: \(tensor.shape)")
            
        } catch {
            print("Error creating tensor: \(error)")
        }
    }
    
    static func formatTensorData(_ data: Data, dataType: ORTTensorDataType) -> String {
        switch dataType {
        case .float:
            let floatData = data.withUnsafeBytes { bytes in
                Array(bytes.bindMemory(to: Float.self))
            }
            return "Float data (\(floatData.count) elements)"
        case .int32:
            let intData = data.withUnsafeBytes { bytes in
                Array(bytes.bindMemory(to: Int32.self))
            }
            return "Int32 data (\(intData.count) elements)"
        default:
            return "Data (\(data.count) bytes)"
        }
    }
}