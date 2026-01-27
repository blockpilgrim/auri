import SwiftUI
import UIKit

struct TextEntrySection: View {
    @Binding var description: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Describe your meal")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextEditor(text: $description)
                .focused($isFocused)
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("e.g., Grilled chicken salad with avocado...")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(.horizontal)
        .onTapGesture {
            isFocused = true
        }
    }
}

#Preview {
    TextEntrySection(description: .constant(""))
}
