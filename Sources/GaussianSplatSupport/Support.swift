import CoreGraphicsSupport
import Foundation
import SIMDSupport

public struct PackedHalf3: Hashable {
    public var x: Float16
    public var y: Float16
    public var z: Float16
}

public struct PackedHalf4: Hashable {
    public var x: Float16
    public var y: Float16
    public var z: Float16
    public var w: Float16
}

public struct SplatC: Equatable {
    public var position: PackedHalf3
    public var color: PackedHalf4
    public var cov_a: PackedHalf3
    public var cov_b: PackedHalf3
}

public func max(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [max(lhs[0], rhs[0]), max(lhs[1], rhs[1]), max(lhs[2], rhs[2])]
}

public func min(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [min(lhs[0], rhs[0]), min(lhs[1], rhs[1]), min(lhs[2], rhs[2])]
}

public extension Collection where Element == PackedFloat3 {
    var bounds: (min: PackedFloat3, max: PackedFloat3) {
        (
            // swiftlint:disable:next reduce_into
            reduce([Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude], GaussianSplatSupport.min),
            // swiftlint:disable:next reduce_into
            reduce([-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude], GaussianSplatSupport.max)
        )
    }
}

extension PackedHalf3 {
    init(_ other: SIMD3<Float>) {
        self = PackedHalf3(x: Float16(other.x), y: Float16(other.y), z: Float16(other.z))
    }
}

extension PackedHalf4 {
    init(_ other: SIMD4<Float>) {
        self = PackedHalf4(x: Float16(other.x), y: Float16(other.y), z: Float16(other.z), w: Float16(other.w))
    }
}

extension FloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        clamp(self, in: range)
    }
}

extension SIMD4 where Scalar == Float {
    func clamped(to range: ClosedRange<Scalar>) -> Self {
        [x.clamped(to: range), y.clamped(to: range), z.clamped(to: range), w.clamped(to: range)]
    }
}

public extension Bundle {
    static let gaussianSplatShaders: Bundle = {
        if let shadersBundleURL = Bundle.main.url(forResource: "SwiftGraphics_GaussianSplatShaders", withExtension: "bundle"), let bundle = Bundle(url: shadersBundleURL) {
            return bundle
        }
        // Fail.
        fatalError("Could not find shaders bundle")
    }()
}

public extension Bundle {

    func bundle(atPath path: [String]) -> Bundle? {
        print(resourcePath)
        print(try! childBundles().map { $0.bundleURL.lastPathComponent })
        guard let bundleURL = url(forResource: path.first, withExtension: "bundle"), let bundle = Bundle(url: bundleURL) else {
            return nil
        }
        print(bundleURL)
        let path = path.dropFirst()
        if path.isEmpty {
            return bundle
        }
        else {
            return bundle.bundle(atPath: Array(path))
        }
    }

    func childBundles() throws -> [Bundle] {
        guard let resourceURL else {
            return []
        }
        let contents = try FileManager().contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: [.contentTypeKey])
        return contents.filter { url in
            guard let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                return false
            }
            return contentType.conforms(to: .bundle)
        }
        .compactMap { url in
            Bundle(url: url)
        }
    }
}
