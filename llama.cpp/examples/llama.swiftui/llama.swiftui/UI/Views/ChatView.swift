import SwiftUI

struct ChatView: View {
    @EnvironmentObject var llamaState: LlamaState
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    @FocusState private var isInputFocused: Bool
    
    // Media pickers
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var showDocumentPicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var selectedFileURL: URL? = nil
    @State private var showMediaBar = false
    
    // Memory & Preferences (optional - doesn't break if not set)
    private let memoryStore: LocalContextStore? = LocalContextStore.shared
    
    var initialPrompt: String?
    
    var body: some View {
        ZStack {
            RuthGradientBackground()
            
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            if isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation(.ruthSmooth) {
                            if let lastId = messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isTyping) { _ in
                        withAnimation(.ruthSmooth) {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
                
                // Input bar
                VStack(spacing: 0) {
                    ChatInputBar(
                        text: $messageText,
                        isInputFocused: _isInputFocused,
                        onSend: sendMessage,
                        onAttach: {
                            withAnimation(.ruthSpring) {
                                showMediaBar.toggle()
                            }
                        }
                    )
                    
                    // Media attachment bar
                    if showMediaBar {
                        MediaAttachmentBar(
                            showImagePicker: $showImagePicker,
                            showVideoPicker: $showVideoPicker,
                            showDocumentPicker: $showDocumentPicker,
                            showCamera: $showCamera
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    BreathingRing()
                        .scaleEffect(0.5)
                    
                    Text("Ruth")
                        .font(Font.ruthHeadline())
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            if let prompt = initialPrompt {
                messageText = prompt
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    sendMessage()
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPicker(selectedVideoURL: $selectedVideoURL)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedFileURL: $selectedFileURL)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                handleImageSelected(image)
                selectedImage = nil
            }
        }
        .onChange(of: selectedVideoURL) { newURL in
            if let url = newURL {
                handleVideoSelected(url)
                selectedVideoURL = nil
            }
        }
        .onChange(of: selectedFileURL) { newURL in
            if let url = newURL {
                handleFileSelected(url)
                selectedFileURL = nil
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        HapticFeedback.medium.trigger()
        
        let userMessage = ChatMessage(
            text: messageText,
            isUser: true,
            source: .local
        )
        
        let promptToSend = messageText
        
        // Log user message to memory store
        memoryStore?.logEvent(.querySubmitted(query: promptToSend, timestamp: Date()))
        
        withAnimation(.ruthSpring) {
            messages.append(userMessage)
        }
        
        messageText = ""
        isInputFocused = false
        
        // Send to real LlamaState
        Task {
            await getRealResponse(for: promptToSend)
        }
    }
    
    private func getRealResponse(for prompt: String) async {
        isTyping = true
        
        // Check if this is a complex instruction that requires planning
        if llamaState.isComplexInstruction(prompt) {
            print("🧠 Complex instruction detected, using Planner + Critic agents")
            
            // Use the planning agents to break down the instruction
            let planResult = await llamaState.handleComplexInstruction(prompt)
            
            let response = ChatMessage(
                text: planResult,
                isUser: false,
                source: .local
            )
            
            // Log the planned steps
            memoryStore?.logEvent(.querySubmitted(query: planResult, timestamp: Date()))
            
            withAnimation(.ruthSpring) {
                messages.append(response)
                isTyping = false
            }
            
            HapticFeedback.success.trigger()
            return
        }
        
        // Use TaskRouter to determine which model to use
        let modelType = llamaState.taskRouter.determineModel(for: prompt)
        _ = llamaState.taskRouter.getModelDescription(for: modelType)
        
        // Check if this is an image generation or other impossible task
        if let intent = ConversationManager.detectIntent(from: prompt),
           intent.toolName == "image_generation" {
            
            let imagePrompt = intent.parameters["prompt"] as? String ?? "unknown"
            
            let response = ChatMessage(
                text: "🎨 Image Generation Request Detected\n\n" +
                      "I'm a text-based AI model and cannot generate images directly.\n\n" +
                      "📸 Your request: \"\(imagePrompt)\"\n\n" +
                      "To generate images, Ruth would need to:\n" +
                      "• Route to cloud image generation service (DALL-E, Stable Diffusion)\n" +
                      "• Integrate with image generation APIs\n" +
                      "• Use specialized image models\n\n" +
                      "💡 For now, try asking me text-based questions, or use the photo/video editing tools for existing media!",
                isUser: false,
                source: .cloud // Indicate this would go to cloud
            )
            
            withAnimation(.ruthSpring) {
                messages.append(response)
                isTyping = false
            }
            
            HapticFeedback.success.trigger()
            return
        }
        
        // Capture messageLog before
        let beforeLog = llamaState.messageLog
        
        // Call the appropriate model based on routing decision
        await llamaState.complete(text: prompt)
        
        // Extract response from messageLog diff
        let afterLog = llamaState.messageLog
        let responseText = extractResponse(before: beforeLog, after: afterLog)
        
        // Determine source based on routing
        let source: ChatMessage.MessageSource = modelType == .remote ? .cloud : .local
        
        let response = ChatMessage(
            text: responseText,
            isUser: false,
            source: source
        )
        
        // Log assistant response to memory store
        memoryStore?.logEvent(.querySubmitted(query: responseText, timestamp: Date()))
        
        withAnimation(.ruthSpring) {
            messages.append(response)
            isTyping = false
        }
        
        HapticFeedback.success.trigger()
    }
    
    private func extractResponse(before: String, after: String) -> String {
        // Extract the new content added to messageLog
        guard after.count > before.count else {
            print("⚠️ No new content in messageLog")
            return "No response generated"
        }
        
        let newContent = String(after.dropFirst(before.count))
        print("📝 Raw new content (\(newContent.count) chars): \(newContent.prefix(200))...")
        
        // Find the actual response by removing known metadata patterns
        var cleanedContent = newContent
        
        // Remove "[Using: Model Name]\n" prefix
        if let usingRange = cleanedContent.range(of: #"\[Using: [^\]]+\]\n"#, options: .regularExpression) {
            cleanedContent.removeSubrange(usingRange)
        }
        
        // Remove the user prompt echo (everything up to and including the first double newline)
        // This handles the case where the model echoes the prompt before responding
        if let doubleNewline = cleanedContent.range(of: "\n\n") {
            // Skip past the prompt echo to get the actual response
            cleanedContent = String(cleanedContent[doubleNewline.upperBound...])
        } else if let firstNewline = cleanedContent.firstIndex(of: "\n") {
            // Fallback: just skip the first line if no double newline found
            let afterFirstLine = String(cleanedContent[cleanedContent.index(after: firstNewline)...])
            // Only remove if the first line looks like the prompt (not the response)
            if !afterFirstLine.isEmpty {
                cleanedContent = afterFirstLine
            }
        }
        
        // Remove trailing statistics ("Done\nHeat up took...\nGenerated...")
        if let doneRange = cleanedContent.range(of: #"\n\s*Done\s*\n"#, options: .regularExpression) {
            cleanedContent = String(cleanedContent[..<doneRange.lowerBound])
        }
        
        // Remove "[Response from ...]" metadata
        if let responseFromRange = cleanedContent.range(of: #"\[Response from [^\]]+\]"#, options: .regularExpression) {
            cleanedContent.removeSubrange(responseFromRange)
        }
        
        // Clean up the result
        let response = cleanedContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Debug: print what we extracted
        print("📝 Extracted response (\(response.count) chars): \(response.prefix(200))...")
        
        if response.isEmpty {
            print("⚠️ Response is empty after cleaning. Raw content was: \(newContent.prefix(500))")
            // Return the raw content with minimal cleaning as fallback
            let fallback = newContent
                .replacingOccurrences(of: #"\[Using: [^\]]+\]\n"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\n\s*Done\s*\n.*$"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return fallback.isEmpty ? "[Model generated empty response]" : fallback
        }
        
        return response
    }
    
    private func simulateResponse() {
        // Old simulation method - kept as fallback
        isTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = ChatMessage(
                text: "I'm here to help! This is a simulated response from Ruth. The actual integration with LlamaState will provide real responses.",
                isUser: false,
                source: .local
            )
            
            withAnimation(.ruthSpring) {
                messages.append(response)
                isTyping = false
            }
            
            HapticFeedback.success.trigger()
        }
    }
    
    // MARK: - Media Handlers
    
    private func handleImageSelected(_ image: UIImage) {
        HapticFeedback.success.trigger()
        showMediaBar = false
        
        let message = ChatMessage(
            text: "[Image attached] 📷\nImage size: \(Int(image.size.width))x\(Int(image.size.height))",
            isUser: true,
            source: .local
        )
        
        withAnimation(.ruthSpring) {
            messages.append(message)
        }
        
        // TODO: Process image with PhotoEditorTool or send to LLM
        print("📷 Image selected: \(image.size)")
    }
    
    private func handleVideoSelected(_ url: URL) {
        HapticFeedback.success.trigger()
        showMediaBar = false
        
        let message = ChatMessage(
            text: "[Video attached] 🎥\n\(url.lastPathComponent)",
            isUser: true,
            source: .local
        )
        
        withAnimation(.ruthSpring) {
            messages.append(message)
        }
        
        // TODO: Process video with VideoEffectsTool
        print("🎥 Video selected: \(url.path)")
    }
    
    private func handleFileSelected(_ url: URL) {
        HapticFeedback.success.trigger()
        showMediaBar = false
        
        let fileName = url.lastPathComponent
        let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64
        let sizeText = fileSize != nil ? " (\(ByteCountFormatter.string(fromByteCount: fileSize!, countStyle: .file)))" : ""
        
        let message = ChatMessage(
            text: "[File attached] 📄\n\(fileName)\(sizeText)",
            isUser: true,
            source: .local
        )
        
        withAnimation(.ruthSpring) {
            messages.append(message)
        }
        
        // TODO: Process file - read content and send to LLM
        print("📄 File selected: \(url.path)")
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let source: MessageSource
    let timestamp = Date()
    
    enum MessageSource {
        case local
        case cloud
    }
}

// MARK: - Chat Message View

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            // Message card
            GlassCard(
                opacity: 0.2,
                cornerRadius: 18,
                glowColor: message.isUser ? Color.ruthCyan : Color.ruthNeonBlue
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.text)
                        .font(Font.ruthBody())
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 8) {
                        Text(timeString)
                            .font(Font.ruthCaption())
                            .foregroundColor(.white.opacity(0.5))
                        
                        if !message.isUser {
                            Spacer()
                            
                            Text(sourceLabel)
                                .font(Font.ruthCaption())
                                .foregroundColor(sourceColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(sourceColor.opacity(0.2))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: 320, alignment: message.isUser ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
    
    private var sourceLabel: String {
        switch message.source {
        case .local: return "local"
        case .cloud: return "cloud"
        }
    }
    
    private var sourceColor: Color {
        switch message.source {
        case .local: return Color.ruthCyan
        case .cloud: return Color.ruthNeonBlue
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dot1Opacity = 0.3
    @State private var dot2Opacity = 0.3
    @State private var dot3Opacity = 0.3
    
    var body: some View {
        HStack(spacing: 4) {
            GlassCard(
                opacity: 0.15,
                cornerRadius: 18,
                glowColor: Color.ruthNeonBlue
            ) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white.opacity(dot1Opacity))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(dot2Opacity))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(dot3Opacity))
                        .frame(width: 8, height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(width: 80)
            
            Spacer()
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            dot1Opacity = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.6).delay(0.2).repeatForever(autoreverses: true)) {
            dot2Opacity = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.6).delay(0.4).repeatForever(autoreverses: true)) {
            dot3Opacity = 1.0
        }
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    @FocusState var isInputFocused: Bool
    var onSend: () -> Void
    var onAttach: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Attach button
            if let attachAction = onAttach {
                Button {
                    HapticFeedback.light.trigger()
                    attachAction()
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 20))
                        .foregroundColor(Color.ruthCyan)
                }
                .iconStyle(glowColor: Color.ruthCyan)
            }
            
            // Text editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Type a message...")
                        .font(Font.ruthBody())
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
                
                TextEditor(text: $text)
                    .font(Font.ruthBody())
                    .foregroundColor(.white)
                    .focused($isInputFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 44, maxHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .background(
                GlassmorphicBackground(
                    opacity: 0.2,
                    cornerRadius: 16,
                    glowColor: isInputFocused ? Color.ruthNeonBlue : Color.white,
                    showGlow: true,
                    glowIntensity: isInputFocused ? 0.8 : 0.2
                )
            )
            
            // Send button
            Button {
                onSend()
            } label: {
                Image(systemName: "arrow.up")
            }
            .sendStyle(enabled: !text.isEmpty)
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.3))
    }
}

// MARK: - Tool Execution Extension

extension ChatView {
    /// Execute a tool by name with JSON payload
    /// Returns the tool result or nil if tool not found
    func executeTool(named name: String, jsonPayload: String) async -> String? {
        do {
            let result = try await ToolRegistry.shared.execute(name, input: ["payload": jsonPayload])
            print("✅ Tool \(name) executed successfully")
            
            // Log tool execution to memory store
            memoryStore?.logEvent(
                .toolExecuted(toolName: name, success: true, timestamp: Date())
            )
            
            return String(describing: result)
        } catch {
            print("❌ Tool \(name) failed: \(error.localizedDescription)")
            
            // Log failed execution
            memoryStore?.logEvent(
                .toolExecuted(toolName: name, success: false, timestamp: Date())
            )
            
            return "Tool error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
