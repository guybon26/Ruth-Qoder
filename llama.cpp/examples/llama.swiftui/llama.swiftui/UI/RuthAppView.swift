import SwiftUI

/// Root navigation container for Ruth Assistant
struct RuthAppView: View {
    @StateObject private var llamaState = LlamaState()
    
    var body: some View {
        HomeView()
            .environmentObject(llamaState)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    RuthAppView()
}
