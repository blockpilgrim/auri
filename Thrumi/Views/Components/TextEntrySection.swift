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
                .background(GlassStyle.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: GlassStyle.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                        .strokeBorder(GlassStyle.borderGradient, lineWidth: GlassStyle.borderWidth)
                )
                .overlay(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("e.g., Grilled chicken salad with avocado...")
                            .foregroundStyle(.white.opacity(0.25))
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
