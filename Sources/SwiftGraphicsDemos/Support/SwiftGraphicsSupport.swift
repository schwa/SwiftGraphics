import CoreGraphics
import CoreGraphicsSupport
import Foundation
import Metal
import MetalKit
import SIMDSupport
import SwiftUI
#if os(macOS)
import AppKit
#endif


public extension MTKMesh {
    /// Total length of all buffers in MTKMesh
    var totalLength: Int {
        let vertexBuffersLength = vertexBuffers.map(\.length).reduce(0, +)
        let submeshesIndexBuffersLength = submeshes.map(\.indexBuffer.length).reduce(0, +)
        return vertexBuffersLength + submeshesIndexBuffersLength
    }
}

public extension SIMD3<Float> {
    func distance(to rhs: SIMD3<Float>) -> Float {
        (self - rhs).length
    }
}

// MARK: -



// MARK: -



// MARK: -


public enum SwiftGraphicsSupportError: Error {
    case illegalValue
    case resourceCreationFailure
    case optionalUnwrapFailure
    case noLibrary
}

public func hslToRgb(_ h: Float, _ s: Float, _ l: Float) -> (Float, Float, Float) {
    if s == 0 {
        return (1, 1, 1)
    } else {
        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q
        let r = hueToRgb(p, q, h + 1 / 3)
        let g = hueToRgb(p, q, h)
        let b = hueToRgb(p, q, h - 1 / 3)
        return (r, g, b)
    }
}

public func hueToRgb(_ p: Float, _ q: Float, _ t: Float) -> Float {
    var t = t
    if t < 0 { t += 1 }
    if t > 1 { t -= 1 }
    if t < 1 / 6 {
        return p + (q - p) * 6 * t
    }
    if t < 1 / 2 {
        return q
    }
    if t < 2 / 3 {
        return p + (q - p) * (2 / 3 - t) * 6
    }
    return p
}

public struct SpatialTapGestureModifier: ViewModifier {
    let callback: (CGPoint) -> Void

    @State
    var start: CGPoint?

    public func body(content: Content) -> some View {
        content.gesture(DragGesture(minimumDistance: 0).onChanged { value in
            if start == nil {
                start = value.location
            }
        }
        .onEnded { value in
            callback(value.location)
        })
    }
}

public extension View {
    func onSpatialTapGesture(_ callback: @escaping (CGPoint) -> Void) -> some View {
        modifier(SpatialTapGestureModifier(callback: callback))
    }
}

public struct ImageLoadError: Error {
    let string: String
}

public extension Image {
    init(url: URL) throws {
        if try url.checkResourceIsReachable() == false {
            throw ImageLoadError(string: "Resource does not exist at: \(url)")
        }
        #if os(macOS)
        guard let nsImage = NSImage(contentsOf: url) else {
            throw ImageLoadError(string: "Cannot load resource at \(url), maybe sandbox issues.")
        }
        self = Image(nsImage: nsImage)
        #elseif os(iOS)
        guard let uiImage = UIImage(contentsOfFile: url.path) else {
            throw ImageLoadError(string: "Cannot load resource at \(url), maybe sandbox issues.")
        }
        self = Image(uiImage: uiImage)
        #endif
    }
}

extension MemoryLayout {
    static func packedStride(of value: T) -> Int {
        switch value {
        case let value as SIMD3<Float>:
            return MemoryLayout<Float>.stride * value.scalarCount
        default:
            return stride
        }
    }
}

public extension MTKTextureLoader {
    func newTexture(for color: CGColor, options: [MTKTextureLoader.Option: Any]? = nil) throws -> MTLTexture {
        let image = try color.makeImage()
        let texture = try newTexture(cgImage: image, options: options)
        texture.label = "CGColor(\(color))"
        return texture
    }
}
