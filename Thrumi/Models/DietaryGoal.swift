import Foundation

enum DietaryGoal: String, Codable, CaseIterable {
    case keto
    case vegetarian
    case vegan
    case mediterranean
    case wholeFood
    case lowSugar
    case highProtein
    case whole30
    case custom

    var displayName: String {
        switch self {
        case .keto: "Keto / Low-Carb"
        case .vegetarian: "Vegetarian"
        case .vegan: "Vegan"
        case .mediterranean: "Mediterranean"
        case .wholeFood: "Whole / Minimally Processed"
        case .lowSugar: "Low Sugar"
        case .highProtein: "High Protein"
        case .whole30: "Whole30 / Paleo"
        case .custom: "Custom"
        }
    }
}
