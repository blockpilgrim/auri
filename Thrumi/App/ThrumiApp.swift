import SwiftData
import SwiftUI

@main
struct ThrumiApp: App {
    let sharedModelContainer: ModelContainer
    let mealService: MealService
    let adherenceEngine: AdherenceEngine
    let userPreferencesService: UserPreferencesService
    let hapticsManager: HapticsManager

    init() {
        let schema = Schema([
            Meal.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let context = sharedModelContainer.mainContext
        mealService = MealService(modelContext: context)
        adherenceEngine = AdherenceEngine(modelContext: context)
        userPreferencesService = UserPreferencesService(modelContext: context)
        hapticsManager = HapticsManager()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.mealService, mealService)
                .environment(\.adherenceEngine, adherenceEngine)
                .environment(\.userPreferences, userPreferencesService)
                .environment(\.hapticsManager, hapticsManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
