import SwiftUI

/// A subtle button to access the Data View from the home screen.
/// Positioned in the top-right corner per the navigation design.
struct DataViewButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chart.bar.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.8))
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel("View Data")
        .accessibilityHint("Opens meal history and adherence statistics")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            HStack {
                Spacer()
                DataViewButton(action: {})
                    .padding()
            }
            Spacer()
        }
    }
}
