import Foundation

enum OrbTier: String, Codable, CaseIterable {
    case dreaming       // 0-29%  (deep rest)
    case resting        // 30-49% (conserving energy)
    case awakening      // 50-69% (gathering energy)
    case vibrant        // 70-89% (strong magical energy)
    case radiant        // 90-100% (full magical resonance)

    var displayName: String {
        switch self {
        case .dreaming: "Dreaming"
        case .resting: "Resting"
        case .awakening: "Awakening"
        case .vibrant: "Vibrant"
        case .radiant: "Radiant"
        }
    }

    static func from(adherence: Double) -> OrbTier {
        switch adherence {
        case 0..<0.30: .dreaming
        case 0.30..<0.50: .resting
        case 0.50..<0.70: .awakening
        case 0.70..<0.90: .vibrant
        default: .radiant
        }
    }
}
