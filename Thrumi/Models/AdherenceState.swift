import Foundation

struct AdherenceState: Equatable {
    let todayAdherence: Double      // 0.0–1.0
    let rolling7Adherence: Double   // 0.0–1.0
    let rolling30Adherence: Double  // 0.0–1.0
    let coreAdherence: Double       // blended: 0.6*today + 0.4*rolling7
    let tier: CoreTier

    static let empty = AdherenceState(
        todayAdherence: 0,
        rolling7Adherence: 0,
        rolling30Adherence: 0,
        coreAdherence: 0,
        tier: .safeMode
    )

    init(
        todayAdherence: Double,
        rolling7Adherence: Double,
        rolling30Adherence: Double
    ) {
        self.todayAdherence = todayAdherence
        self.rolling7Adherence = rolling7Adherence
        self.rolling30Adherence = rolling30Adherence
        self.coreAdherence = 0.60 * todayAdherence + 0.40 * rolling7Adherence
        self.tier = CoreTier.from(adherence: coreAdherence)
    }

    private init(
        todayAdherence: Double,
        rolling7Adherence: Double,
        rolling30Adherence: Double,
        coreAdherence: Double,
        tier: CoreTier
    ) {
        self.todayAdherence = todayAdherence
        self.rolling7Adherence = rolling7Adherence
        self.rolling30Adherence = rolling30Adherence
        self.coreAdherence = coreAdherence
        self.tier = tier
    }
}
