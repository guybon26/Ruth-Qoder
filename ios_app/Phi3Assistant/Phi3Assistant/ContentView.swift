//
//  ContentView.swift
//  Phi3Assistant
//
//  Created by Guy Bonnen on 09/11/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var modelHandler = ModelHandler()
    @State private var userInput: String = ""
    @State private var response: String = "Welcome to Phi3 Assistant! Ask me anything."
    @State private var isProcessing: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Response area
                ScrollView {
                    Text(response)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .frame(maxHeight: .infinity)
                
                // Input area
                VStack(spacing: 10) {
                    TextField("Ask me anything...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isProcessing)
                    
                    Button(action: processQuery) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text(isProcessing ? "Processing..." : "Send")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isProcessing || userInput.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Phi3 Assistant")
            .padding()
        }
    }
    
    private func processQuery() {
        guard !userInput.isEmpty else { return }
        
        isProcessing = true
        let query = userInput
        userInput = ""
        
        // Process in background
        DispatchQueue.global(qos: .userInitiated).async {
            let result = modelHandler.processQuery(query)
            
            DispatchQueue.main.async {
                response = result
                isProcessing = false
            }
        }
    }
}

#Preview {
    ContentView()
}
