import Everything
import Metal
import MetalKit
import ModelIO
import Observation
import RenderKitShadersLegacy
import SIMDSupport
import SwiftFormats
import SwiftUI

// https://www.youtube.com/watch?v=rSKMYc1CQHE&t=1746s

protocol SimulationStorage {
    associatedtype Positions: MutableCollection, RandomAccessCollection where Positions.Element == SIMD2<Float>, Positions.Index == Int, Positions.Index.Stride == Int
    associatedtype Velocities: MutableCollection, RandomAccessCollection where Velocities.Element == SIMD2<Float>, Velocities.Index == Int, Velocities.Index.Stride == Int
    associatedtype Densities: MutableCollection, RandomAccessCollection where Densities.Element == Float, Densities.Index == Int, Densities.Index.Stride == Int

    var positions: Positions { get set }
    var velocities: Velocities { get set }
    var densities: Densities { get set }
}

class Simulation<Storage>: Observable where Storage: SimulationStorage {
//    struct Parameters {
//        var count: Int
//        var gravity: SIMD2<Float> = [0, 100]
//        var smoothingRadius: Float = 50
//        var collisionDampingFactor: Float = 0.7
//        var mass: Float = 1
//        var targetDensity: Float = 2.75
//        var pressureMultiplier: Float = 25
//        var particleRadius: Float = 5
//        var speed: Float = 1
//        var enablePressure = true
//    }

    var count: Int
    var gravity: SIMD2<Float> = [0, 0]
    var smoothingRadius: Float = 50
    var collisionDampingFactor: Float = 0.7
    var mass: Float = 1
    var targetDensity: Float = 0.004
    var pressureMultiplier: Float = 26
    var particleRadius: Float = 5
    var speed: Float = 1
    var enablePressure = true
    var size: CGSize = .zero

    struct Statistics {
        var minSpeed: Float = 0
        var maxSpeed: Float = 0
        var averageSpeed: Float = 0
        var minDensity: Float = 0
        var maxDensity: Float = 0
        var averageDensity: Float = 0
    }

    var statistics = Statistics()

    @ObservationIgnored
    var storage: Storage

    @ObservationIgnored
    var table: SpatialLookupTable<Storage.Positions>

    var lastTime: CFTimeInterval?

    var step = 0

    init(
        count: Int,
        storage: Storage,
        size: CGSize
    ) {
        self.count = count
        self.storage = storage
        self.size = size
        table = .init(size: SIMD2<Float>(size))
    }

    func populate() {
        for index in storage.positions.startIndex ..< storage.positions.endIndex {
            storage.positions[index].x = Float.random(in: 0 ..< Float(size.width))
            storage.positions[index].y = Float.random(in: 0 ..< Float(size.height))
        }
        for index in storage.velocities.startIndex ..< storage.velocities.endIndex {
            storage.velocities[index] = (SIMD2<Float>.random(in: 0 ..< 2) - [1, 1]) * 0
        }
        for index in storage.densities.startIndex ..< storage.densities.endIndex {
            storage.densities[index] = Float(0.0)
        }
        table = .init(size: SIMD2<Float>(size))
    }

    func step(time: TimeInterval) {
        guard let lastTime else {
            self.lastTime = time
            return
        }
        step += 1

        let deltaTime = Float(time - lastTime) * speed
        self.lastTime = time

        for index in storage.positions.startIndex ..< storage.positions.endIndex {
            storage.velocities[index] += gravity * deltaTime
            storage.densities[index] = calculateDensity(storage.positions[index])
        }

        table.update(points: storage.positions, radius: smoothingRadius)

        if enablePressure {
            for i in storage.positions.startIndex ..< storage.positions.endIndex {
                let pressureForce = calculatePressureForce(i)
                let pressureAcceleration = pressureForce / storage.densities[i]
                storage.velocities[i] += pressureAcceleration * deltaTime
            }
        }

        for index in storage.positions.startIndex ..< storage.positions.endIndex {
            storage.positions[index] += storage.velocities[index] * deltaTime
            resolveCollisions(index: index)
        }

        statistics.maxDensity = storage.densities.reduce(Float.zero, max)
        statistics.minDensity = storage.densities.reduce(Float.zero, min)
        statistics.averageDensity = storage.densities.reduce(Float.zero, +) / Float(storage.densities.count)

        let speeds = storage.velocities.map(\.magnitude)
        statistics.maxSpeed = speeds.reduce(Float.zero, max)
        statistics.minSpeed = speeds.reduce(Float.zero, min)
        statistics.averageSpeed = speeds.reduce(Float.zero, +) / Float(speeds.count)
    }

    private func resolveCollisions(index: Int) {
        let size = SIMD2<Float>(size)
        var position = storage.positions[index]
        var velocity = storage.velocities[index]

        let xRange = particleRadius ... size.x - particleRadius
        let yRange = particleRadius ... size.y - particleRadius
        if !xRange.contains(position.x) {
            position.x = clamp(position.x, in: xRange)
            velocity.x *= -1 * collisionDampingFactor
            velocity.y *= 1 * collisionDampingFactor
        }
        if !yRange.contains(position.y) {
            position.y = clamp(position.y, in: yRange)
            velocity.x *= 1 * collisionDampingFactor
            velocity.y *= -1 * collisionDampingFactor
        }

        storage.positions[index] = position
        storage.velocities[index] = velocity
    }

    private func calculateDensity(_ samplePoint: SIMD2<Float>) -> Float {
        var density: Float = 0
        let mass: Float = 1
        // Loop over all particle positions
        // TODO: optimize to only look at particles inside the smoothing radius
        for position in storage.positions {
            let dst = (position - samplePoint).magnitude
            let influence = smoothingKernel(radius: smoothingRadius, dst: dst)
            density += mass * influence
        }
        return density
    }

    private func smoothingKernel(radius: Float, dst: Float) -> Float {
        if dst >= radius {
            return 0
        }
        let volume = (.pi * pow(radius, 4)) / 6
        return (radius - dst) * (radius - dst) / volume
    }

    private func smoothingKernelDerivative(dst: Float, radius: Float) -> Float {
        if dst >= radius {
            return 0
        }
        let scale = 12 / (pow(radius, 4) * .pi)
        return (dst - radius) * scale
    }

    private func calculatePressureForce(_ particleIndex: Int) -> SIMD2<Float> {
        var pressureForce = SIMD2<Float>.zero

        let samplePoint = storage.positions[particleIndex]
        table.indicesNear(point: samplePoint) { i in
            if particleIndex == i {
                return
            }
            let dst = (storage.positions[i] - samplePoint).magnitude
            // SIMD2<Float> dir = dst == 0 ? GetRandomDir): offset / dst
            let offset = storage.positions[i] - samplePoint
            let dir = dst == 0 ? .randomDirection : offset / dst
            let slope = smoothingKernelDerivative(dst: dst, radius: smoothingRadius)
            let density = storage.densities[i]
            let sharedPressure = -calculateSharedPressure(densityA: density, densityB: storage.densities[particleIndex])
            pressureForce += sharedPressure * dir * slope * mass / density
        }
        return pressureForce
    }

    private func convertDensityToPressure(_ density: Float) -> Float {
        let densityError = density - targetDensity
        return densityError * pressureMultiplier
    }

    private func calculateSharedPressure(densityA: Float, densityB: Float) -> Float {
        let pressureA = convertDensityToPressure(densityA)
        let pressureB = convertDensityToPressure(densityB)
        return (pressureA + pressureB) / 2
    }
}

// MARK: -

struct UnsafeBufferSimulationStorage: SimulationStorage {
    var positions: UnsafeMutableBufferPointer<SIMD2<Float>>
    var velocities: UnsafeMutableBufferPointer<SIMD2<Float>>
    var densities: UnsafeMutableBufferPointer<Float>
}

struct ArraySimulatorStorage: SimulationStorage {
    var positions: [SIMD2<Float>]
    var velocities: [SIMD2<Float>]
    var densities: [Float]
}

// MARK: -

typealias Vector2 = SIMD2<Float>

extension SIMD2 where Scalar == Float {
    var magnitude: Scalar {
        simd_length(self)
    }

    var sqrMagnitude: Scalar {
        simd_length_squared(self)
    }

    static var right: Self {
        [1, 0]
    }

    static var up: Self {
        [0, 1]
    }

    static var randomDirection: Self {
        let angle = Float.random(in: 0 ... .pi * 2)
        return [cos(angle), sin(angle)]
    }
}
