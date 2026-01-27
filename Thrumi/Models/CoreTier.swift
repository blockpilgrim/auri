import Foundation

enum CoreTier: String, Codable, CaseIterable {
    case safeMode       // 0-29%
    case standby        // 30-49%
    case stabilizing    // 50-69%
    case online         // 70-89%
    case phaseLocked    // 90-100%

    var displayName: String {
        switch self {
        case .safeMode: "Safe Mode"
        case .standby: "Standby"
        case .stabilizing: "Stabilizing"
        case .online: "Online"
        case .phaseLocked: "Phase-Locked"
        }
    }

    static func from(adherence: Double) -> CoreTier {
        switch adherence {
        case 0..<0.30: .safeMode
        case 0.30..<0.50: .standby
        case 0.50..<0.70: .stabilizing
        case 0.70..<0.90: .online
        default: .phaseLocked
        }
    }
}
