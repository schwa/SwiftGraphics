import Foundation
import simd
import SIMDSupport

public extension Collection where Element == SplatB {
    func downsamplePositions(bits: Int) -> [SplatB] {
        let positions = self.map { SIMD3<Float>($0.position) }
        // swiftlint:disable:next reduce_into
        let minimums = positions.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], simd.min)
        // swiftlint:disable:next reduce_into
        let maximums = positions.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], simd.max)
        let size = maximums - minimums
        let maxInt = Float(2 << bits)
        return self.map { splat in
            let position = SIMD3<Float>(splat.position)
            let scaledPosition = (position - minimums) / size
            let intPosition = floor(scaledPosition * maxInt)
            let rescaledPosition = intPosition / maxInt
            let finalPosition = rescaledPosition * (maximums - minimums) + minimums
            var splat = splat
            splat.position = PackedFloat3(finalPosition)
            return splat
        }
    }

    func downsampleScale(bits: Int) -> [SplatB] {
        let values = self.map { SIMD3<Float>($0.scale) }
        // swiftlint:disable:next reduce_into
        let minimums = values.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], simd.min)
        // swiftlint:disable:next reduce_into
        let maximums = values.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], simd.max)
        let size = maximums - minimums
        let maxInt = Float(2 << bits)
        return self.map { splat in
            let value = SIMD3<Float>(splat.scale)
            let scaled = (value - minimums) / size
            let floored = floor(scaled * maxInt)
            let rescaled = floored / maxInt
            let final = rescaled * (maximums - minimums) + minimums
            var splat = splat
            splat.scale = PackedFloat3(final)
            return splat
        }
    }

    func downsampleColor() -> [SplatB] {
        return self.map { splat in
            var splat = splat
            splat.color.x = ((splat.color.x >> 3) & 0b0001_1111) << 3
            splat.color.y = ((splat.color.y >> 2) & 0b0011_1111) << 2
            splat.color.z = ((splat.color.z >> 3) & 0b0001_1111) << 3
            splat.color.a = ((splat.color.a >> 4) & 0b0000_1111) << 4
            return splat
        }
    }
}
