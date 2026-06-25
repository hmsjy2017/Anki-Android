import SwiftUI
import AnkiIOSPort

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.play")
                .font(.system(size: 48))
                .foregroundStyle(.accent)
            Text("AnkiDroid")
                .font(.largeTitle.bold())
            Text("iOS/iPadOS port scaffold")
                .font(.headline)
            Text("Review UI will connect to the shared AnkiIOSPort review session boundary.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
