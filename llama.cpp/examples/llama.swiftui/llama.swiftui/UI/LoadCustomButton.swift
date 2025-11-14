import SwiftUI
import UniformTypeIdentifiers

struct LoadCustomButton: View {
    @ObservedObject private var llamaState: LlamaState
    @State private var showFileImporter = false

    init(llamaState: LlamaState) {
        self.llamaState = llamaState
    }

    var body: some View {
        VStack {
            Button(action: {
                showFileImporter = true
            }) {
                Text("Load Custom Model")
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType(filenameExtension: "gguf", conformingTo: .data)!],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                files.forEach { file in
                    let gotAccess = file.startAccessingSecurityScopedResource()
                    if !gotAccess { return }

                    do {
                        // Copy file to documents directory to avoid security-scoped resource issues
                        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let destinationURL = documentsURL.appendingPathComponent(file.lastPathComponent)
                        
                        // Remove existing file if it exists
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        
                        // Copy the file
                        try FileManager.default.copyItem(at: file, to: destinationURL)
                        
                        // Load the copied file
                        try llamaState.loadModel(modelUrl: destinationURL)
                    } catch let err {
                        print("Error: \(err.localizedDescription)")
                    }

                    file.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
