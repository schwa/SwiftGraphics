import AsyncAlgorithms
import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import os
import simd
import SIMDSupport

internal class CPUSplatRadixSorter <Splat> where Splat: SplatProtocol {
    private var device: MTLDevice
    private var temporaryIndexedDistances: [IndexedDistance]
    private var capacity: Int
    private var logger: Logger?

    internal init(device: MTLDevice, capacity: Int) {
        self.device = device
        self.capacity = capacity
        releaseAssert(capacity > 0, "You shouldn't be creating a sorter with a capacity of zero.")
        temporaryIndexedDistances = .init(repeating: .init(), count: capacity)
    }

    internal func sort(splats: TypedMTLBuffer<Splat>, camera: simd_float4x4, model: simd_float4x4, reversed: Bool) throws -> TypedMTLBuffer<IndexedDistance> {
        var currentIndexedDistances = try device.makeTypedBuffer(element: IndexedDistance.self, capacity: capacity).labelled("Splats-IndexDistances-\(Date.now.iso8601)")
        cpuRadixSort(splats: splats, indexedDistances: &currentIndexedDistances, temporaryIndexedDistances: &temporaryIndexedDistances, camera: camera, model: model, reversed: reversed)
        return currentIndexedDistances
    }
}

extension Date {
    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        formatter.formatOptions.remove(.withColonSeparatorInTime)
        formatter.formatOptions.remove(.withDashSeparatorInDate)
        return formatter.string(from: self)
    }
}

// MARK: -

private func cpuRadixSort<Splat>(splats: TypedMTLBuffer<Splat>, indexedDistances: inout TypedMTLBuffer<IndexedDistance>, temporaryIndexedDistances: inout [IndexedDistance], camera: simd_float4x4, model: simd_float4x4, reversed: Bool) where Splat: SplatProtocol {
    guard !splats.isEmpty else {
        return
    }
    releaseAssert(splats.count <= indexedDistances.capacity, "Too few indexed distances \(indexedDistances.count) for \(splats.capacity) splats.")
    releaseAssert(splats.count <= temporaryIndexedDistances.count, "Too few temporary indexed distances \(temporaryIndexedDistances.count) for \(splats.count) splats.")
    indexedDistances.withUnsafeMutableBufferPointer { indexedDistances in
        let indexedDistances = UnsafeMutableBufferPointer<IndexedDistance>(start: indexedDistances.baseAddress, count: splats.count)
        // Compute distances.
        let modelView = camera.inverse * model
        releaseAssert(splats.count <= indexedDistances.count, "Cannot sort \(splats.count) splats into \(indexedDistances.count) indexed distances.")
        splats.withUnsafeBufferPointer { splats in
            for index in 0..<splats.count {
                let position = modelView * SIMD4<Float>(splats[index].floatPosition, 1.0)
                let distance = position.z * (reversed ? -1.0 : 1.0)
                indexedDistances[index] = .init(index: UInt32(index), distanceToCamera: distance)
            }
        }
        temporaryIndexedDistances.withUnsafeMutableBufferPointer { temporaryIndexedDistances in
            let temporaryIndexedDistances = UnsafeMutableBufferPointer<IndexedDistance>(start: temporaryIndexedDistances.baseAddress, count: splats.count)
            releaseAssert(splats.count == indexedDistances.count, "Mismatch between splats \(splats.count) and indexed distances \(indexedDistances.count).")
            releaseAssert(splats.count == temporaryIndexedDistances.count, "Mismatch between splats \(splats.count) and temporary indexed distances \(temporaryIndexedDistances.count).")
            releaseAssert(temporaryIndexedDistances.count == indexedDistances.count, "Mismatch between temporary indexed distances \(temporaryIndexedDistances.count) and indexed distances \(indexedDistances.count).")
            RadixSortCPU<IndexedDistance>().radixSort(input: indexedDistances, temp: temporaryIndexedDistances)
        }
    }
    indexedDistances.count = splats.count
}

// MARK: -

extension IndexedDistance: RadixSortable {
    func key(shift: Int) -> Int {
        let bits = distanceToCamera.bitPattern
        let signMask: UInt32 = 0x80000000
        let key: UInt32 = (bits & signMask != 0) ? ~bits : bits ^ signMask
        return (Int(key) >> shift) & 0xFF
    }
}

// MARK: -

extension IndexedDistance: @unchecked @retroactive Sendable {
}
