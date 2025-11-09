import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isProcessing = false
    @State private var modelStatus = "Not Loaded"
    @StateObject private var modelHandler = ModelHandler()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Phi-3 Mini Assistant")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Model Status:")
                        .font(.headline)
                    Text(modelStatus)
                        .font(.caption)
                        .foregroundColor(modelHandler.isModelLoaded() ? .green : .red)
                }
                
                Text("Enter your query below:")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .frame(height: 100)
                    .padding()
                    .border(Color.gray, width: 1)
                
                Button(action: processQuery) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Process Query")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isProcessing || inputText.isEmpty || !modelHandler.isModelLoaded())
                
                Text("Response:")
                    .font(.headline)
                
                ScrollView {
                    Text(outputText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding()
                .border(Color.gray, width: 1)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Phi-3 Assistant")
        }
        .onAppear {
            updateModelStatus()
        }
    }
    
    private func updateModelStatus() {
        if modelHandler.isModelLoaded() {
            modelStatus = "Loaded Successfully"
        } else {
            modelStatus = "Not Loaded"
        }
    }
    
    private func processQuery() {
        isProcessing = true
        outputText = "Processing your query..."
        
        // Process the query in the background
        DispatchQueue.global(qos: .userInitiated).async {
            let response = modelHandler.processQuery(inputText)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                outputText = response
                isProcessing = false
                updateModelStatus()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}