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
}
