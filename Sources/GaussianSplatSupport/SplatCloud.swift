import AsyncAlgorithms
import BaseSupport
import GaussianSplatShaders
import Metal
import MetalSupport
import os
import simd
import SIMDSupport

// TODO: @unchecked Sendable
public final class SplatCloud <Splat>: Equatable, @unchecked Sendable where Splat: SplatProtocol {
    public private(set) var splats: TypedMTLBuffer<Splat>
    internal var indexedDistances: SplatIndices // TODO: Rename from indexedDistances -> indices
    public var label: String?

    // MARK: -

    public init(device: MTLDevice, splats: TypedMTLBuffer<Splat>) throws {
        self.splats = splats
        self.indexedDistances = try AsyncSortManager.sort(device: device, splats: splats, camera: .identity, model: .identity, reversed: false)
    }

    public convenience init(device: MTLDevice, capacity: Int) throws {
        let splats = try device.makeTypedBuffer(element: Splat.self, capacity: capacity)
        try self.init(device: device, splats: splats)
    }

    public convenience init(device: MTLDevice, splats: [Splat]) throws {
        let splats = try device.makeTypedBuffer(data: splats)
        try self.init(device: device, splats: splats)
    }

    // MARK: -

    public static func == (lhs: SplatCloud, rhs: SplatCloud) -> Bool {
        lhs.splats == rhs.splats && lhs.indexedDistances == rhs.indexedDistances
    }

    /// How many splats are currently in the splat cloud
    public var count: Int {
        splats.count
    }

    /// How many splats can the splat cloud actually fit
    public var capacity: Int {
        splats.capacity
    }

    // Note: rely on caller to request a sort
    public func append(splats: [Splat]) throws {
        try self.splats.append(contentsOf: splats)
    }
}

extension SplatCloud: CustomDebugStringConvertible {
    public var debugDescription: String {
        "SplatCloud<\(type(of: Splat.self))>(splats: \(splats), indexedDistances: \(indexedDistances))"
    }
}

struct SplatIndices: Sendable, Equatable {
    var state: SortState
    var indices: TypedMTLBuffer<IndexedDistance>
}

extension SplatIndices: CustomDebugStringConvertible {
    public var debugDescription: String {
        "SplatIndices(state: \(state), indices: \(String(describing: indices.label)) / \(indices.count)/\(indices.capacity)"
    }
}

// MARK: -

struct SortState: Sendable, Equatable {
    var camera: simd_float4x4
    var model: simd_float4x4
    var reversed: Bool
    var count: Int
}

extension SortState: CustomDebugStringConvertible {
    var debugDescription: String {
        return "SortState(camera: \(String(format: "%02X", camera.hashValue)), model: \(String(format: "%02X", model.hashValue)), reversed: \(reversed), count: \(count))"
    }
}

extension SortState {
    var shortDescription: String {
        return "[\(String(format: "%02X", camera.hashValue))|\(String(format: "%02X", model.hashValue))|\(reversed ? "􀄨" : "􀄩")|\(count))]"
    }

}

extension SIMD3<Float> {
    var shortDescription: String {
        "[\(x.formatted()), \(y.formatted()), \(z.formatted())]"
    }
}

extension simd_float4x4 {
    // swiftlint:disable:next legacy_hashing
    var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    func hash(into hasher: inout Hasher) {
        scalars.hash(into: &hasher)
    }
}
