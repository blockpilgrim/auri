import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Text("Thrumi")
            .font(.largeTitle)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Meal.self, UserSettings.self], inMemory: true)
}
