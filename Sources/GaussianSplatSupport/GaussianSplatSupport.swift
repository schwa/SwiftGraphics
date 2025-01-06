import BaseSupport
import CoreGraphics
import Foundation
import Metal
import MetalKit
import os
import RenderKitSceneGraph
import simd
import SIMDSupport

// swiftlint:disable force_unwrapping

// MARK: -

internal extension Node {
    func splats <Splat>(_ type: Splat.Type) -> SplatCloud<Splat>? where Splat: SplatProtocol {
        content as? SplatCloud<Splat>
    }
}

internal extension MTLRenderPassColorAttachmentDescriptor {
    var size: SIMD2<Float> {
        get throws {
            guard let texture else {
                throw BaseError.error(.invalidParameter)
            }
            return SIMD2<Float>(Float(texture.width), Float(texture.height))
        }
    }
}

internal func releaseAssert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    if !condition() {
        fatalError(message(), file: file, line: line)
    }
}

public extension CGImage {
    func convert(bitmapInfo: CGBitmapInfo) -> CGImage? {
        let width = width
        let height = height
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}

internal func convertCGImageEndianness2(_ inputImage: CGImage) -> CGImage? {
    let width = inputImage.width
    let height = inputImage.height
    let bitsPerComponent = 8
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // Choose the appropriate bitmap info for the target endianness
    let bitmapInfo: CGBitmapInfo
    if inputImage.byteOrderInfo == .order32Little {
        bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
    } else {
        bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    }

    guard let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: bitsPerComponent,
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
        return nil
    }

    // Draw the original image into the new context
    context.draw(inputImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    // Create a new CGImage from the context
    return context.makeImage()
}

internal extension MTLSize {
    var shortDescription: String {
        depth == 1 ? "\(width)x\(height)" : "\(width)x\(height)x\(depth)"
    }
}

extension Node {
    static func skybox(device: MTLDevice, texture: MTLTexture) throws -> Node {
        let allocator = MTKMeshBufferAllocator(device: device)
        let panoramaMDLMesh = MDLMesh(sphereWithExtent: [200, 200, 200], segments: [36, 36], inwardNormals: true, geometryType: .triangles, allocator: allocator)
        let panoramaMTKMesh = try MTKMesh(mesh: panoramaMDLMesh, device: device)
        return Node(label: "skyBox", content: Geometry(mesh: panoramaMTKMesh, materials: [PanoramaMaterial(baseColorTexture: texture)]))
    }
}

extension MTLDevice {
    func makeTexture(pixelFormat: MTLPixelFormat, size: SIMD2<Int>, mipmapped: Bool = false, storageMode: MTLStorageMode = .private, usage: MTLTextureUsage, label: String? = nil) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: size.x, height: size.y, mipmapped: mipmapped)
        descriptor.storageMode = storageMode
        descriptor.usage = usage
        let texture = try makeTexture(descriptor: descriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        texture.label = label
        return texture
    }
}

extension MTLDevice {
    func makeBuffer<T>(data: UnsafeBufferPointer<T>, options: MTLResourceOptions = []) -> MTLBuffer? {
        makeBuffer(bytes: data.baseAddress!, length: data.count * MemoryLayout<T>.size, options: options)
    }
}

extension simd_float4x4 {
    static let zero = simd_float4x4()

    var isZero: Bool {
        self == .zero
    }
}
