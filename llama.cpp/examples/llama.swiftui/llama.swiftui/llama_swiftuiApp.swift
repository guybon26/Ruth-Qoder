import SwiftUI

@main
struct llama_swiftuiApp: App {
    var body: some Scene {
        WindowGroup {
            // Switch between original and Ruth UI
            // ContentView()  // Original llama.swift UI
            RuthAppView()    // New futuristic Ruth UI
        }
    }
}
