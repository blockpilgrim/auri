import Foundation
import RealityKit
import UIKit
import simd

/// Particle effects system for the Fusion Core.
///
/// Per PRODUCT.md, particles communicate power state:
/// - Sparks: Small glowing particles (teal or orange), 20%+ adherence
/// - Energy Arcs: Lightning-like jagged lines, 50%+ adherence
/// - Flashes: Bright burst pulses, 60%+ adherence
///
/// At 0-20% adherence: No particles. The Core is calm and quiet.
@MainActor
final class ParticleSystem {
    let container: Entity

    private let sparkContainer: Entity
    private let arcContainer: Entity
    private let flashContainer: Entity

    private var sparks: [Spark] = []
    private var arcs: [EnergyArc] = []
    private var flashes: [Flash] = []

    private var lastSparkTime: TimeInterval = 0
    private var lastArcTime: TimeInterval = 0
    private var lastFlashTime: TimeInterval = 0

    private let ringRadii: [Float]
    private let unitScale: Float

    private enum Limits {
        static let maxSparks = 35
        static let maxArcs = 5
        static let maxFlashes = 4
    }

    init(ringRadii: [Float], unitScale: Float) {
        self.ringRadii = ringRadii
        self.unitScale = unitScale

        container = Entity()
        container.name = "ParticleSystem"

        sparkContainer = Entity()
        sparkContainer.name = "Sparks"
        arcContainer = Entity()
        arcContainer.name = "Arcs"
        flashContainer = Entity()
        flashContainer.name = "Flashes"

        container.addChild(sparkContainer)
        container.addChild(arcContainer)
        container.addChild(flashContainer)
    }

    // MARK: - Update

    func update(
        interpolator: StateInterpolator,
        deltaTime: Float,
        currentTime: TimeInterval,
        thermalMultiplier: Float,
        enabled: Bool
    ) {
        let adherence = interpolator.adherence

        // Clear all particles if disabled or below threshold.
        if !enabled || thermalMultiplier < 0.01 || adherence < 0.20 {
            clearAll()
            return
        }

        updateSparks(interpolator: interpolator, deltaTime: deltaTime, currentTime: currentTime, thermal: thermalMultiplier)
        updateArcs(interpolator: interpolator, deltaTime: deltaTime, currentTime: currentTime, thermal: thermalMultiplier)
        updateFlashes(interpolator: interpolator, deltaTime: deltaTime, currentTime: currentTime, thermal: thermalMultiplier)
    }

    // MARK: - Clear

    private func clearAll() {
        for spark in sparks { spark.entity.removeFromParent() }
        for arc in arcs { arc.entity.removeFromParent() }
        for flash in flashes { flash.entity.removeFromParent() }
        sparks.removeAll()
        arcs.removeAll()
        flashes.removeAll()
    }

    // MARK: - Sparks

    private func updateSparks(interpolator: StateInterpolator, deltaTime: Float, currentTime: TimeInterval, thermal: Float) {
        // Update existing sparks.
        sparks.removeAll { spark in
            spark.update(deltaTime: deltaTime)
            if spark.isExpired {
                spark.entity.removeFromParent()
                return true
            }
            return false
        }

        let intensity = interpolator.sparkIntensity
        guard intensity > 0, sparks.count < Limits.maxSparks else { return }

        // Spawn rate: none at threshold, occasional at 50%, constant at 100%.
        let rate = (12.0 * pow(intensity, 1.8)) * thermal
        guard rate > 0 else { return }

        let interval = 1.0 / Double(rate)
        guard currentTime - lastSparkTime >= interval else { return }
        lastSparkTime = currentTime

        // Randomize color (60% teal, 40% orange).
        let isTeal = Float.random(in: 0...1) < 0.6
        let color = isTeal ? CoreColors.coreTeal : CoreColors.coilGlow

        let spark = Spark.create(color: color, position: randomRingPosition(), unitScale: unitScale)
        sparkContainer.addChild(spark.entity)
        sparks.append(spark)
    }

    // MARK: - Arcs

    private func updateArcs(interpolator: StateInterpolator, deltaTime: Float, currentTime: TimeInterval, thermal: Float) {
        // Update existing arcs.
        arcs.removeAll { arc in
            arc.update(deltaTime: deltaTime)
            if arc.isExpired {
                arc.entity.removeFromParent()
                return true
            }
            return false
        }

        let adherence = interpolator.adherence
        guard adherence >= 0.50, arcs.count < Limits.maxArcs else { return }

        let t = clamp01((adherence - 0.50) / 0.50)
        let baseInterval = Double(lerp(0.45, 0.18, t))
        let interval = baseInterval / Double(max(0.2, thermal))
        guard currentTime - lastArcTime >= interval else { return }
        lastArcTime = currentTime

        let endpoints = randomArcEndpoints()
        let arcColor = CoreColors.blend(CoreColors.coreTeal, CoreColors.whiteHot, t: clamp01((adherence - 0.75) / 0.25) * 0.4)

        let arc = EnergyArc.create(start: endpoints.start, end: endpoints.end, color: arcColor, unitScale: unitScale)
        arcContainer.addChild(arc.entity)
        arcs.append(arc)
    }

    // MARK: - Flashes

    private func updateFlashes(interpolator: StateInterpolator, deltaTime: Float, currentTime: TimeInterval, thermal: Float) {
        // Update existing flashes.
        flashes.removeAll { flash in
            flash.update(deltaTime: deltaTime)
            if flash.isExpired {
                flash.entity.removeFromParent()
                return true
            }
            return false
        }

        let adherence = interpolator.adherence
        guard adherence >= 0.60, flashes.count < Limits.maxFlashes else { return }

        let t = clamp01((adherence - 0.60) / 0.40)
        let baseInterval = Double(lerp(0.85, 0.28, t))
        let interval = baseInterval / Double(max(0.2, thermal))
        guard currentTime - lastFlashTime >= interval else { return }
        lastFlashTime = currentTime

        // At 80%+, more flashes spawn on rings instead of center.
        let ringChance = clamp01((adherence - 0.80) / 0.20) * 0.45 + 0.10
        let position: SIMD3<Float>
        if Float.random(in: 0...1) < ringChance {
            position = randomRingPosition()
        } else {
            position = [0, 0, 0]
        }

        let flashColor = CoreColors.blend(CoreColors.whiteHot, CoreColors.coreTeal, t: 0.3)
        let flash = Flash.create(position: position, color: flashColor, unitScale: unitScale)
        flashContainer.addChild(flash.entity)
        flashes.append(flash)
    }

    // MARK: - Position Helpers

    private func randomRingPosition() -> SIMD3<Float> {
        let radius = ringRadii.randomElement() ?? (0.06 * unitScale)
        let angle = Float.random(in: 0...(2 * .pi))
        let y = Float.random(in: -0.008...0.008)
        return [cos(angle) * radius, y, sin(angle) * radius]
    }

    private func randomArcEndpoints() -> (start: SIMD3<Float>, end: SIMD3<Float>) {
        // 40% chance to arc from center to ring.
        if Float.random(in: 0...1) < 0.40 {
            return (start: [0, 0, 0], end: randomRingPosition())
        }

        // Otherwise, arc between two ring positions.
        var a = randomRingPosition()
        var b = randomRingPosition()

        // Ensure some separation.
        if distance(a, b) < 0.025 {
            b = randomRingPosition()
        }

        // Small lift for visual separation.
        a.y += 0.008
        b.y += 0.008

        return (start: a, end: b)
    }

    // MARK: - Utilities

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * clamp01(t)
    }

    private func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}

// MARK: - Spark

@MainActor
final class Spark {
    let entity: ModelEntity
    var isExpired: Bool { lifetime >= maxLifetime }

    private var lifetime: Float = 0
    private let maxLifetime: Float
    private var velocity: SIMD3<Float>
    private let baseColor: UIColor

    private init(entity: ModelEntity, baseColor: UIColor, velocity: SIMD3<Float>, maxLifetime: Float) {
        self.entity = entity
        self.baseColor = baseColor
        self.velocity = velocity
        self.maxLifetime = maxLifetime
    }

    static func create(color: UIColor, position: SIMD3<Float>, unitScale: Float) -> Spark {
        let mesh = MeshResource.generateSphere(radius: 0.0025 * unitScale / 0.045) // Normalize to unit scale.
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, 0.92))
        material.blending = .transparent(opacity: 0.92)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Spark"
        entity.position = position

        // Velocity: outward and upward.
        let outward = normalize(SIMD3<Float>(position.x, 0, position.z) + [0.0001, 0, 0.0001])
        let outwardSpeed = Float.random(in: 0.10...0.24)
        let upSpeed = Float.random(in: 0.05...0.14)
        let velocity = outward * outwardSpeed + [0, upSpeed, 0]

        let lifetime = Float.random(in: 0.30...0.80)
        return Spark(entity: entity, baseColor: color, velocity: velocity, maxLifetime: lifetime)
    }

    func update(deltaTime: Float) {
        lifetime += deltaTime
        entity.position += velocity * deltaTime
        velocity *= pow(0.90, deltaTime * 60.0) // Drag.

        let t = min(1, lifetime / maxLifetime)
        let alpha = pow(1.0 - t, 2.0)
        let scale = 1.0 - t * 0.3

        entity.scale = [scale, scale, scale]

        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(baseColor, alpha))
        material.blending = .transparent(opacity: .init(floatLiteral: alpha))
        entity.model?.materials = [material]
    }
}

// MARK: - Energy Arc

@MainActor
final class EnergyArc {
    let entity: Entity
    var isExpired: Bool { lifetime >= maxLifetime }

    private var lifetime: Float = 0
    private let maxLifetime: Float
    private let color: UIColor

    private init(entity: Entity, color: UIColor, maxLifetime: Float) {
        self.entity = entity
        self.color = color
        self.maxLifetime = maxLifetime
    }

    static func create(start: SIMD3<Float>, end: SIMD3<Float>, color: UIColor, unitScale: Float) -> EnergyArc {
        let container = Entity()
        container.name = "EnergyArc"

        // Generate jagged path.
        let segmentCount = Int.random(in: 5...8)
        let points = jaggedPath(start: start, end: end, segments: segmentCount)

        for i in 0..<(points.count - 1) {
            let a = points[i]
            let b = points[i + 1]
            let dir = b - a
            let len = max(0.002, length(dir))

            let thickness: Float = 0.0018 * unitScale / 0.045
            let segMesh = MeshResource.generateBox(width: thickness, height: thickness, depth: len)

            var material = UnlitMaterial()
            material.color = .init(tint: CoreColors.withAlpha(color, 0.88))
            material.blending = .transparent(opacity: 0.88)

            let segment = ModelEntity(mesh: segMesh, materials: [material])
            segment.name = "ArcSegment"
            segment.position = (a + b) * 0.5

            let zAxis: SIMD3<Float> = [0, 0, 1]
            segment.transform.rotation = simd_quatf(from: zAxis, to: normalize(dir))
            container.addChild(segment)
        }

        let lifetime = Float.random(in: 0.10...0.25)
        return EnergyArc(entity: container, color: color, maxLifetime: lifetime)
    }

    func update(deltaTime: Float) {
        lifetime += deltaTime
        let t = min(1, lifetime / maxLifetime)
        let alpha = pow(1.0 - t, 2.0)

        for child in entity.children {
            guard let model = child as? ModelEntity else { continue }
            var material = UnlitMaterial()
            material.color = .init(tint: CoreColors.withAlpha(color, alpha))
            material.blending = .transparent(opacity: .init(floatLiteral: alpha))
            model.model?.materials = [material]
        }
    }

    private static func jaggedPath(start: SIMD3<Float>, end: SIMD3<Float>, segments: Int) -> [SIMD3<Float>] {
        var points: [SIMD3<Float>] = [start]
        let dir = end - start
        let len = max(0.001, length(dir))
        let forward = normalize(dir)

        // Build perpendicular axes.
        let up: SIMD3<Float> = abs(forward.y) > 0.9 ? [1, 0, 0] : [0, 1, 0]
        let right = normalize(cross(forward, up))
        let up2 = normalize(cross(right, forward))

        for i in 1..<segments {
            let t = Float(i) / Float(segments)
            let base = start + dir * t
            let jitter = (right * Float.random(in: -1...1) + up2 * Float.random(in: -1...1)) * (0.05 * len)
            points.append(base + jitter)
        }

        points.append(end)
        return points
    }
}

// MARK: - Flash

@MainActor
final class Flash {
    let entity: ModelEntity
    var isExpired: Bool { lifetime >= maxLifetime }

    private var lifetime: Float = 0
    private let maxLifetime: Float
    private let color: UIColor

    private init(entity: ModelEntity, color: UIColor, maxLifetime: Float) {
        self.entity = entity
        self.color = color
        self.maxLifetime = maxLifetime
    }

    static func create(position: SIMD3<Float>, color: UIColor, unitScale: Float) -> Flash {
        let radius: Float = 0.016 * unitScale / 0.045
        let mesh = MeshResource.generateSphere(radius: radius)

        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, 0.88))
        material.blending = .transparent(opacity: 0.88)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Flash"
        entity.position = position

        let lifetime = Float.random(in: 0.15...0.25)
        return Flash(entity: entity, color: color, maxLifetime: lifetime)
    }

    func update(deltaTime: Float) {
        lifetime += deltaTime
        let t = min(1, lifetime / maxLifetime)
        let easeOut = 1.0 - pow(1.0 - t, 2.0)

        let scale = lerp(0.8, 1.9, easeOut)
        entity.scale = [scale, scale, scale]

        let alpha = pow(1.0 - t, 2.0) * 0.88
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, alpha))
        material.blending = .transparent(opacity: .init(floatLiteral: alpha))
        entity.model?.materials = [material]
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * max(0, min(1, t))
    }
}
