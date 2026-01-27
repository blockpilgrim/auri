import UIKit

struct CoreColors {
    // Palette (per rebuild directive)
    static let coreTeal = UIColor(red: 0.31, green: 0.82, blue: 0.77, alpha: 1.0)      // #4FD1C5
    static let lightTeal = UIColor(red: 0.51, green: 0.90, blue: 0.85, alpha: 1.0)     // #81E6D9
    static let copperBase = UIColor(red: 0.72, green: 0.45, blue: 0.20, alpha: 1.0)    // #B87333
    static let coilGlow = UIColor(red: 0.96, green: 0.68, blue: 0.33, alpha: 1.0)      // #F6AD55
    static let whiteHot = UIColor.white                                               // #FFFFFF

    static func withAlpha(_ color: UIColor, _ alpha: Float) -> UIColor {
        color.withAlphaComponent(CGFloat(max(0, min(1, alpha))))
    }

    /// Inner core shifts toward white at 80%+ adherence.
    /// At 100%: ~30% blend toward white.
    static func innerCoreColor(adherence: Float) -> UIColor {
        let t = clamp01((adherence - 0.80) / 0.20)
        let whiteBlend = t * 0.30
        return blend(lightTeal, whiteHot, t: whiteBlend)
    }

    static func blend(_ a: UIColor, _ b: UIColor, t: Float) -> UIColor {
        let t = CGFloat(clamp01(t))
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red: r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue: b1 + (b2 - b1) * t,
            alpha: 1.0
        )
    }

    private static func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}
