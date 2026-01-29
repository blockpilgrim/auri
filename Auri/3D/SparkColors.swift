import UIKit

/// Color palette for Auri sparks - soft, magical tones representing your inner light.
///
/// Visual style: Cel-shaded / stylized - NOT photorealistic
/// Inspired by: Biophotons, Studio Ghibli magic, Ori and the Blind Forest
struct SparkColors {
    // MARK: - Cool Blues (Low Adherence: 0-30%)

    static let coolBlue = UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)
    static let deepBlue = UIColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 1.0)

    // MARK: - Teals & Cyans (Medium Adherence: 30-60%)

    static let teal = UIColor(red: 0.3, green: 0.8, blue: 0.8, alpha: 1.0)
    static let cyan = UIColor(red: 0.4, green: 0.9, blue: 0.95, alpha: 1.0)

    // MARK: - Purples & Violets (Medium-High Adherence: 40-70%)

    static let purple = UIColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 1.0)
    static let violet = UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0)

    // MARK: - Warm Golds & Ambers (High Adherence: 60-85%)

    static let gold = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
    static let amber = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)

    // MARK: - Pinks & Roses (High Adherence: 60-85%)

    static let pink = UIColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 1.0)
    static let rose = UIColor(red: 1.0, green: 0.5, blue: 0.7, alpha: 1.0)

    // MARK: - White (Peak Adherence: 85-100%)

    static let white = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0)

    // MARK: - Palette Selection

    /// Returns color palette appropriate for adherence level.
    ///
    /// | Adherence | Colors |
    /// |-----------|--------|
    /// | 0-30%     | Cool blues, dim |
    /// | 30-50%    | Blue-teal |
    /// | 50-70%    | Teal-purple |
    /// | 70-85%    | Gold-teal-pink |
    /// | 85-100%   | Full spectrum, white cores |
    static func palette(for adherence: Float) -> [UIColor] {
        switch adherence {
        case 0..<0.3:
            return [coolBlue, deepBlue]
        case 0.3..<0.5:
            return [coolBlue, teal, cyan]
        case 0.5..<0.7:
            return [teal, purple, violet]
        case 0.7..<0.85:
            return [teal, gold, pink, purple]
        default:
            return [white, gold, pink, teal, cyan, purple]
        }
    }

    /// Brightness multiplier for adherence level.
    /// 0% = 40% brightness, 100% = 100% brightness
    static func brightness(for adherence: Float) -> Float {
        0.4 + clamp01(adherence) * 0.6
    }

    // MARK: - Utility Functions

    static func withAlpha(_ color: UIColor, _ alpha: Float) -> UIColor {
        color.withAlphaComponent(CGFloat(clamp01(alpha)))
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

    /// Returns a random color from the given palette.
    static func randomColor(from palette: [UIColor]) -> UIColor {
        palette.randomElement() ?? coolBlue
    }

    private static func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}
