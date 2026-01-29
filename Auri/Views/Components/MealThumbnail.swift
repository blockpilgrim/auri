import SwiftUI
import UIKit

struct MealThumbnail: View {
    let path: String
    @State private var image: UIImage?
    @Environment(\.mealService) private var mealService

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                GlassStyle.cardFill
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            image = mealService?.loadPhoto(at: path)
        }
    }
}
