import Foundation
import RealityKit
import UIKit
import simd

@MainActor
final class ParticleEffectsManager {
    let container: Entity

    private let sparkContainer = Entity()
    private let arcContainer = Entity()
    private let flashContainer = Entity()

    private var activeSparks: [Spark] = []
    private var activeArcs: [Arc] = []
    private var activeFlashes: [Flash] = []

    private var lastSparkTime: TimeInterval = 0
    private var lastArcTime: TimeInterval = 0
    private var lastFlashTime: TimeInterval = 0

    private let ringRadii: [Float]

    private enum Limits {
        static let maxSparks = 40
        static let maxArcs = 6
        static let maxFlashes = 5
    }

    init(ringRadii: [Float]) {
        self.ringRadii = ringRadii

        container = Entity()
        container.name = "ParticleEffects"

        sparkContainer.name = "Sparks"
        arcContainer.name = "Arcs"
        flashContainer.name = "Flashes"

        container.addChild(sparkContainer)
        container.addChild(arcContainer)
        container.addChild(flashContainer)
    }

    func update(
        interpolator: StateInterpolator,
        deltaTime: Float,
        currentTime: TimeInterval,
        thermalParticleMultiplier: Float,
        showParticles: Bool
    ) {
        let adherence = interpolator.adherence

        if !showParticles || thermalParticleMultiplier <= 0.01 || adherence <= 0.20 {
            clearAll()
            return
        }

        updateSparks(interpolator: interpolator, deltaTime: deltaTime, currentTime: currentTime, thermalParticleMultiplier: thermalParticleMultiplier)
        updateArcs(interpolator: interpolator, deltaTime: deltaTime, currentTime: currentTime, thermalParticleMultiplier: thermalParticleMultiplier)
        updateFlashes(interpolator: interpolator, deltaTime: deltaTime, currentTime: currentTime, thermalParticleMultiplier: thermalParticleMultiplier)
    }

    private func clearAll() {
        for spark in activeSparks { spark.entity.removeFromParent() }
        for arc in activeArcs { arc.entity.removeFromParent() }
        for flash in activeFlashes { flash.entity.removeFromParent() }
        activeSparks.removeAll()
        activeArcs.removeAll()
        activeFlashes.removeAll()
    }

    // MARK: - Sparks

    private func updateSparks(
        interpolator: StateInterpolator,
        deltaTime: Float,
        currentTime: TimeInterval,
        thermalParticleMultiplier: Float
    ) {
        activeSparks.removeAll { spark in
            spark.update(deltaTime: deltaTime)
            if spark.isExpired {
                spark.entity.removeFromParent()
                return true
            }
            return false
        }

        let intensity = interpolator.sparkIntensity
        guard intensity > 0 else { return }
        guard activeSparks.count < Limits.maxSparks else { return }

        // None at threshold; occasional at ~50%; constant at 100%.
        let rate = (14.0 * pow(intensity, 2.0)) * thermalParticleMultiplier
        guard rate > 0 else { return }

        let interval = 1.0 / Double(rate)
        guard currentTime - lastSparkTime >= interval else { return }
        lastSparkTime = currentTime

        let isTeal = Float.random(in: 0...1) < 0.6
        let color = isTeal ? CoreColors.coreTeal : CoreColors.coilGlow

        let spark = Spark.create(color: color, spawnPosition: randomRingPosition())
        sparkContainer.addChild(spark.entity)
        activeSparks.append(spark)
    }

    // MARK: - Arcs

    private func updateArcs(
        interpolator: StateInterpolator,
        deltaTime: Float,
        currentTime: TimeInterval,
        thermalParticleMultiplier: Float
    ) {
        activeArcs.removeAll { arc in
            arc.update(deltaTime: deltaTime)
            if arc.isExpired {
                arc.entity.removeFromParent()
                return true
            }
            return false
        }

        let adherence = interpolator.adherence
        guard adherence >= 0.50 else { return }
        guard activeArcs.count < Limits.maxArcs else { return }

        let t = clamp01((adherence - 0.50) / 0.50)
        let baseInterval = Double(lerp(0.40, 0.15, t))
        let interval = baseInterval / Double(max(0.2, thermalParticleMultiplier))
        guard currentTime - lastArcTime >= interval else { return }
        lastArcTime = currentTime

        let endpoints = randomArcEndpoints(adherence: adherence)
        let arcColor = CoreColors.blend(CoreColors.coreTeal, CoreColors.whiteHot, t: clamp01((adherence - 0.80) / 0.20) * 0.5)
        let arc = Arc.create(start: endpoints.start, end: endpoints.end, color: arcColor)
        arcContainer.addChild(arc.entity)
        activeArcs.append(arc)
    }

    // MARK: - Flashes

    private func updateFlashes(
        interpolator: StateInterpolator,
        deltaTime: Float,
        currentTime: TimeInterval,
        thermalParticleMultiplier: Float
    ) {
        activeFlashes.removeAll { flash in
            flash.update(deltaTime: deltaTime)
            if flash.isExpired {
                flash.entity.removeFromParent()
                return true
            }
            return false
        }

        let adherence = interpolator.adherence
        guard adherence >= 0.60 else { return }
        guard activeFlashes.count < Limits.maxFlashes else { return }

        let t = clamp01((adherence - 0.60) / 0.40)
        let baseInterval = Double(lerp(0.90, 0.25, t))
        let interval = baseInterval / Double(max(0.2, thermalParticleMultiplier))
        guard currentTime - lastFlashTime >= interval else { return }
        lastFlashTime = currentTime

        let ringFlashT = clamp01((adherence - 0.80) / 0.20)
        let spawnOnRingChance = 0.10 + 0.45 * ringFlashT

        let position: SIMD3<Float>
        if Float.random(in: 0...1) < Float(spawnOnRingChance) {
            position = randomRingPosition()
        } else {
            position = [0, 0, 0]
        }

        let color = CoreColors.blend(CoreColors.whiteHot, CoreColors.coreTeal, t: 0.35)
        let flash = Flash.create(position: position, color: color)
        flashContainer.addChild(flash.entity)
        activeFlashes.append(flash)
    }

    // MARK: - Spawn helpers

    private func randomRingPosition() -> SIMD3<Float> {
        let radius = ringRadii.randomElement() ?? 0.08
        let angle = Float.random(in: 0...(2 * .pi))
        let y = Float.random(in: -0.01...0.01)
        return [cos(angle) * radius, y, sin(angle) * radius]
    }

    private func randomArcEndpoints(adherence: Float) -> (start: SIMD3<Float>, end: SIMD3<Float>) {
        if Float.random(in: 0...1) < 0.40 {
            return (start: [0, 0, 0], end: randomRingPosition())
        }

        var a = randomRingPosition()
        var b = randomRingPosition()
        if distance(a, b) < 0.03 {
            b = randomRingPosition()
        }

        let lift = lerp(0.0, 0.02, adherence)
        a.y += lift
        b.y += lift
        return (start: a, end: b)
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * clamp01(t) }
    private func clamp01(_ x: Float) -> Float { max(0, min(1, x)) }
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

    static func create(color: UIColor, spawnPosition: SIMD3<Float>) -> Spark {
        let mesh = MeshResource.generateSphere(radius: 0.003)
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, 0.95))
        material.blending = .transparent(opacity: 0.95)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Spark"
        entity.position = spawnPosition

        let outward = normalize(SIMD3<Float>(spawnPosition.x, 0, spawnPosition.z) + SIMD3<Float>(0.0001, 0, 0.0001))
        let outwardSpeed = Float.random(in: 0.12...0.28)
        let upSpeed = Float.random(in: 0.06...0.16)
        let velocity = outward * outwardSpeed + SIMD3<Float>(0, upSpeed, 0)

        let lifetime = Float.random(in: 0.30...0.80)
        return Spark(entity: entity, baseColor: color, velocity: velocity, maxLifetime: lifetime)
    }

    func update(deltaTime: Float) {
        lifetime += deltaTime
        entity.position += velocity * deltaTime
        velocity *= pow(0.92, deltaTime * 60.0)

        let t = min(1, lifetime / maxLifetime)
        let alpha = pow(1.0 - t, 2.0)
        entity.scale = [1.0 - t * 0.25, 1.0 - t * 0.25, 1.0 - t * 0.25]

        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(baseColor, alpha))
        material.blending = .transparent(opacity: .init(floatLiteral: alpha))
        entity.model?.materials = [material]
    }
}

// MARK: - Arc

@MainActor
final class Arc {
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

    static func create(start: SIMD3<Float>, end: SIMD3<Float>, color: UIColor) -> Arc {
        let container = Entity()
        container.name = "EnergyArc"

        let segmentCount = Int.random(in: 6...10)
        let points = jaggedPoints(start: start, end: end, segments: segmentCount)

        for i in 0..<(points.count - 1) {
            let a = points[i]
            let b = points[i + 1]
            let dir = b - a
            let len = max(0.003, length(dir))

            let segMesh = MeshResource.generateBox(width: 0.0022, height: 0.0022, depth: len)
            var material = UnlitMaterial()
            material.color = .init(tint: CoreColors.withAlpha(color, 0.85))
            material.blending = .transparent(opacity: 0.85)

            let seg = ModelEntity(mesh: segMesh, materials: [material])
            seg.name = "ArcSegment"
            seg.position = (a + b) * 0.5

            let zAxis: SIMD3<Float> = [0, 0, 1]
            seg.transform.rotation = simd_quatf(from: zAxis, to: normalize(dir))
            container.addChild(seg)
        }

        let lifetime = Float.random(in: 0.10...0.25)
        return Arc(entity: container, color: color, maxLifetime: lifetime)
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

    private static func jaggedPoints(start: SIMD3<Float>, end: SIMD3<Float>, segments: Int) -> [SIMD3<Float>] {
        var pts: [SIMD3<Float>] = [start]
        let dir = end - start
        let len = max(0.001, length(dir))
        let forward = normalize(dir)

        let up: SIMD3<Float> = abs(forward.y) > 0.9 ? [1, 0, 0] : [0, 1, 0]
        let right = normalize(cross(forward, up))
        let up2 = normalize(cross(right, forward))

        for i in 1..<segments {
            let t = Float(i) / Float(segments)
            let base = start + dir * t
            let jitter = (right * Float.random(in: -1...1) + up2 * Float.random(in: -1...1)) * (0.06 * len)
            pts.append(base + jitter)
        }

        pts.append(end)
        return pts
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

    static func create(position: SIMD3<Float>, color: UIColor) -> Flash {
        let mesh = MeshResource.generateSphere(radius: 0.020)
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, 0.85))
        material.blending = .transparent(opacity: 0.85)

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

        let scale = lerp(0.8, 1.8, easeOut)
        entity.scale = [scale, scale, scale]

        let alpha = pow(1.0 - t, 2.0) * 0.85
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, alpha))
        material.blending = .transparent(opacity: .init(floatLiteral: alpha))
        entity.model?.materials = [material]
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * max(0, min(1, t)) }
}
