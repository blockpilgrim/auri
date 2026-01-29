import Foundation
import SwiftData

@Model
final class Meal {
    var id: UUID
    var timestamp: Date
    var photoPath: String?
    var mealDescription: String?
    var isOnTrack: Bool
    var source: MealSource

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        photoPath: String? = nil,
        mealDescription: String? = nil,
        isOnTrack: Bool,
        source: MealSource
    ) {
        self.id = id
        self.timestamp = timestamp
        self.photoPath = photoPath
        self.mealDescription = mealDescription
        self.isOnTrack = isOnTrack
        self.source = source
    }
}
