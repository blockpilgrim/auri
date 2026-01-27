import SwiftUI

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No meals logged yet")
                .font(.headline)

            Text("Log your first meal to start tracking")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    EmptyHistoryView()
}
