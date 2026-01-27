import Foundation
import SwiftData
import UIKit

@Observable
final class MealService {
    private let modelContext: ModelContext

    private static let photoDirectoryName = "MealPhotos"
    private static let jpegCompressionQuality: CGFloat = 0.75

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        ensurePhotoDirectoryExists()
    }

    // MARK: - CRUD Operations

    func saveMeal(_ meal: Meal) throws {
        modelContext.insert(meal)
        try modelContext.save()
    }

    func deleteMeal(_ meal: Meal) throws {
        if let photoPath = meal.photoPath {
            try? deletePhoto(at: photoPath)
        }
        modelContext.delete(meal)
        try modelContext.save()
    }

    func getMealsForDate(_ date: Date) -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return getMealsInRange(from: startOfDay, to: endOfDay)
    }

    func getMealsInRange(from startDate: Date, to endDate: Date) -> [Meal] {
        let predicate = #Predicate<Meal> { meal in
            meal.timestamp >= startDate && meal.timestamp < endDate
        }
        let descriptor = FetchDescriptor<Meal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    // MARK: - Photo Management

    func savePhoto(_ image: UIImage, for mealId: UUID) throws -> String {
        guard let data = image.jpegData(compressionQuality: Self.jpegCompressionQuality) else {
            throw MealServiceError.imageCompressionFailed
        }

        let filename = "\(mealId.uuidString).jpg"
        let relativePath = "\(Self.photoDirectoryName)/\(filename)"
        let fullURL = Self.documentsDirectory.appendingPathComponent(relativePath)

        try data.write(to: fullURL)
        return relativePath
    }

    func loadPhoto(at path: String) -> UIImage? {
        let fullURL = Self.documentsDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: fullURL) else {
            return nil
        }
        return UIImage(data: data)
    }

    func deletePhoto(at path: String) throws {
        let fullURL = Self.documentsDirectory.appendingPathComponent(path)
        try FileManager.default.removeItem(at: fullURL)
    }

    func cleanupOrphanedPhotos() throws {
        let photoDirectory = Self.documentsDirectory.appendingPathComponent(Self.photoDirectoryName)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: photoDirectory.path) else {
            return
        }

        let files = try fileManager.contentsOfDirectory(at: photoDirectory, includingPropertiesForKeys: nil)

        let descriptor = FetchDescriptor<Meal>()
        let allMeals = try modelContext.fetch(descriptor)
        let validPaths = Set(allMeals.compactMap { $0.photoPath })

        for fileURL in files {
            let relativePath = "\(Self.photoDirectoryName)/\(fileURL.lastPathComponent)"
            if !validPaths.contains(relativePath) {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    // MARK: - Private Helpers

    private func ensurePhotoDirectoryExists() {
        let photoDirectory = Self.documentsDirectory.appendingPathComponent(Self.photoDirectoryName)
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: photoDirectory.path) {
            try? fileManager.createDirectory(at: photoDirectory, withIntermediateDirectories: true)
        }
    }

    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

enum MealServiceError: Error, LocalizedError {
    case imageCompressionFailed

    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image to JPEG format"
        }
    }
}
