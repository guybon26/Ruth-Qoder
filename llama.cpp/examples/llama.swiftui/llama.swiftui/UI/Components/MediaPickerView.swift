import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Video Picker

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                parent.selectedVideoURL = url
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFileURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    var allowedContentTypes: [UTType] = [.item]
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedFileURL = url
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Media Attachment Bar

struct MediaAttachmentBar: View {
    @Binding var showImagePicker: Bool
    @Binding var showVideoPicker: Bool
    @Binding var showDocumentPicker: Bool
    @Binding var showCamera: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Camera
            Button {
                HapticFeedback.light.trigger()
                showCamera = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                    Text("Camera")
                        .font(Font.ruthCaption())
                }
                .foregroundColor(Color.ruthNeonBlue)
                .frame(maxWidth: .infinity)
            }
            
            // Photos
            Button {
                HapticFeedback.light.trigger()
                showImagePicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 20))
                    Text("Photos")
                        .font(Font.ruthCaption())
                }
                .foregroundColor(Color.ruthCyan)
                .frame(maxWidth: .infinity)
            }
            
            // Videos
            Button {
                HapticFeedback.light.trigger()
                showVideoPicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 20))
                    Text("Videos")
                        .font(Font.ruthCaption())
                }
                .foregroundColor(Color.ruthNeonBlue)
                .frame(maxWidth: .infinity)
            }
            
            // Files
            Button {
                HapticFeedback.light.trigger()
                showDocumentPicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 20))
                    Text("Files")
                        .font(Font.ruthCaption())
                }
                .foregroundColor(Color.ruthCyan)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            GlassmorphicBackground(
                opacity: 0.15,
                cornerRadius: 16,
                glowColor: Color.ruthNeonBlue,
                showGlow: true,
                glowIntensity: 0.3
            )
        )
    }
}

// MARK: - Model Selector

struct ModelSelectorView: View {
    @EnvironmentObject var llamaState: LlamaState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                RuthGradientBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Downloaded Models
                        if !llamaState.downloadedModels.isEmpty {
                            SectionHeader(title: "Downloaded Models")
                            
                            ForEach(llamaState.downloadedModels) { model in
                                ModelRow(
                                    model: model,
                                    isLoading: llamaState.isLoadingModel,
                                    onSelect: {
                                        Task {
                                            await loadModel(model)
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Available for Download
                        if !llamaState.undownloadedModels.isEmpty {
                            SectionHeader(title: "Available for Download")
                            
                            ForEach(llamaState.undownloadedModels) { model in
                                DownloadModelRow(
                                    model: model,
                                    onDownload: {
                                        Task {
                                            await downloadModel(model)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .ruthSafeArea()
                }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.ruthNeonBlue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func loadModel(_ model: Model) async {
        // Check if model exists in Documents directory
        var modelURL = llamaState.getDocumentsDirectory().appendingPathComponent(model.filename)
        
        // If not in Documents, check project models directory
        if !FileManager.default.fileExists(atPath: modelURL.path) {
            let projectModelPath = "/Users/guybonnen/Ruth-Qoder/models/\(model.filename)"
            if FileManager.default.fileExists(atPath: projectModelPath) {
                modelURL = URL(fileURLWithPath: projectModelPath)
            }
        }
        
        // Load the model
        if FileManager.default.fileExists(atPath: modelURL.path) {
            try? await llamaState.loadModel(modelUrl: modelURL)
            dismiss()
        } else {
            print("❌ Model file not found: \(model.filename)")
        }
    }
    
    private func downloadModel(_ model: Model) async {
        // Trigger download via LlamaState with progress tracking
        await llamaState.downloadModel(model)
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(Font.ruthSubheadline())
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ModelRow: View {
    let model: Model
    let isLoading: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            HapticFeedback.medium.trigger()
            onSelect()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "cpu")
                    .font(.system(size: 24))
                    .foregroundColor(Color.ruthNeonBlue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(Font.ruthSubheadline())
                        .foregroundColor(.white)
                    
                    Text(model.filename)
                        .font(Font.ruthCaption())
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .tint(Color.ruthCyan)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.ruthCyan)
                }
            }
            .padding(16)
            .background(
                GlassmorphicBackground(
                    opacity: 0.2,
                    cornerRadius: 16,
                    glowColor: Color.ruthNeonBlue
                )
            )
        }
    }
}

struct DownloadModelRow: View {
    let model: Model
    let onDownload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                if !model.isDownloading {
                    HapticFeedback.medium.trigger()
                    onDownload()
                }
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    if model.isDownloading {
                        ProgressView()
                            .tint(Color.ruthCyan)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 24))
                            .foregroundColor(Color.ruthCyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.name)
                            .font(Font.ruthSubheadline())
                            .foregroundColor(.white)
                        
                        if model.isDownloading {
                            Text("Downloading... \(Int(model.downloadProgress * 100))%")
                                .font(Font.ruthCaption())
                                .foregroundColor(Color.ruthCyan)
                        } else {
                            Text("Tap to download")
                                .font(Font.ruthCaption())
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    GlassmorphicBackground(
                        opacity: 0.15,
                        cornerRadius: 16,
                        glowColor: Color.ruthCyan
                    )
                )
            }
            .disabled(model.isDownloading)
            
            // Progress bar
            if model.isDownloading {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        // Progress fill with gradient
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.ruthNeonBlue, Color.ruthCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * model.downloadProgress, height: 6)
                            .animation(.ruthSmooth, value: model.downloadProgress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 16)
            }
        }
    }
}
