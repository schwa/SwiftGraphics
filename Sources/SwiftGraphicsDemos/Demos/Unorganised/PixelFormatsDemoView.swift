import BaseSupport
@preconcurrency import Metal
import MetalKit
import MetalSupport
import MetalUnsafeConformances
import SwiftUI

struct PixelFormatsDemoView: View, DemoView {
    @Environment(\.metalDevice)
    var device

    @State
    private var texture: MTLTexture?

    @State
    private var convertedTextures: [MTLPixelFormat: MTLTexture] = [:]

    init() {
    }

    var body: some View {
        List {
            ForEach(MTLPixelFormat.allCases, id: \.self) { pixelFormat in
                Text("\(pixelFormat.description) \(convertedTextures[pixelFormat] != nil)")
            }
        }
        .task {
            let device = MTLCreateSystemDefaultDevice()!
            let loader = MTKTextureLoader(device: device)
            let texture = try! await loader.newTexture(name: "seamless-foods-mixed-0020", scaleFactor: 1.0, bundle: .module)
            await MainActor.run {
                self.texture = texture
            }
            for pixelFormat in MTLPixelFormat.allCases {
                guard let converted = texture.converted(to: pixelFormat) else {
                    continue
                }
                convertedTextures[pixelFormat] = converted
            }
        }
    }
}

extension MTLTexture {
    func converted(to pixelFormat: MTLPixelFormat) -> MTLTexture? {
        guard pixelFormat != self.pixelFormat else {
            print("Skipping. Destination pixel format same as source pixel format (\(pixelFormat))")
            return nil
        }
        guard pixelFormat != .invalid else {
            print("Skipping. Destination pixel format invalid.")
            return nil
        }
        guard let metadata = self.pixelFormat.metadata else {
            print("Skipping. No metadata for source pixel format (\(self.pixelFormat)).")
            return nil
        }
        guard let otherMetadata = pixelFormat.metadata else {
            print("Skipping. No metadata for destination pixel format (\(pixelFormat)).")
            return nil
        }
        guard metadata.channels == otherMetadata.channels else {
            print("Skipping. Incompatible channels for \(pixelFormat) and \(self.pixelFormat).")
            return nil
        }
        guard metadata.convertsSRGB == otherMetadata.convertsSRGB else {
            print("Skipping. Incompatible srgb for \(pixelFormat) and \(self.pixelFormat).")
            return nil
        }
        guard metadata.extendedRange == otherMetadata.extendedRange else {
            print("Skipping. Incompatible extendedRange for \(pixelFormat) and \(self.pixelFormat).")
            return nil
        }
        guard metadata.compressed == otherMetadata.compressed else {
            print("Skipping. Incompatible compressed for \(pixelFormat) and \(self.pixelFormat).")
            return nil
        }
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        let destinationTextureDescriptor = MTLTextureDescriptor(self)
        destinationTextureDescriptor.pixelFormat = pixelFormat
        guard let destinationTexture = device.makeTexture(descriptor: destinationTextureDescriptor) else {
            return nil
        }
        commandQueue.withCommandBuffer(waitAfterCommit: true) { commandBuffer in
            let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
            blitEncoder.copy(from: self, to: destinationTexture)
            blitEncoder.endEncoding()
        }
        return destinationTexture
    }
}

struct PixelFormatMetadata {
    enum Endianness {
        case none
        case big
        case little
    }

    enum ChannelType {
        case unknown
        case unsignedInteger
        case signedInteger
        case normalizedUnsignedInteger
        case normalizedSignedInteger
        case float
        case fixedPoint
    }

    enum Usage {
        case color
        case depth
        case stencil
        case depthAndStencil
    }

    var usage: Usage
    var channels: Int
    var channelType: ChannelType
    var convertsSRGB: Bool
    var compressed: Bool
    var endianness: Endianness
    var includesAlpha: Bool
    var extendedRange: Bool

    static func color(channels: Int, channelType: ChannelType, compressed: Bool = false, endianness: Endianness, includesAlpha: Bool = false, extendedRange: Bool = false) -> Self {
        .init(usage: .color, channels: channels, channelType: channelType, convertsSRGB: false, compressed: compressed, endianness: endianness, includesAlpha: includesAlpha, extendedRange: extendedRange)
    }

    static func srgbColor(channels: Int, channelType: ChannelType, compressed: Bool = false, endianness: Endianness, includesAlpha: Bool = false, extendedRange: Bool = false) -> Self {
        .init(usage: .color, channels: channels, channelType: channelType, convertsSRGB: true, compressed: compressed, endianness: endianness, includesAlpha: includesAlpha, extendedRange: extendedRange)
    }
}

extension PixelFormatMetadata {
    init?(parsing format: String) {
        if format.hasPrefix("bc") || format.hasPrefix("pvrtc") || format.hasPrefix("eac") || format.hasPrefix("etc2") || format.hasPrefix("astc") {
            return nil
        }

        let convertsSRGB = format.hasSuffix("_srgb")
        let channelType: ChannelType = if format.contains("Unorm") {
            .normalizedUnsignedInteger
        }
        else if format.contains("Snorm") {
            .normalizedSignedInteger
        }
        else if format.contains("Uint") {
            .unsignedInteger
        }
        else if format.contains("Sint") {
            .signedInteger
        }
        else if format.contains("Float") {
            .float
        }
        else if format.contains("bgr10_xr") || format.contains("bgra10_xr") {
            .fixedPoint
        }
        else if format.contains("gbgr422") || format.contains("bgrg422") {
            .unknown
        }
        else {
            .unknown
        }

        let usage: Usage
        let channels: Int
        let includesAlpha: Bool
        if format.hasPrefix("rgba") || format.hasPrefix("bgra") {
            usage = .color
            channels = 4
            includesAlpha = true
        }
        else if format.hasPrefix("r8") || format.hasPrefix("r16") || format.hasPrefix("r32") {
            usage = .color
            channels = 1
            includesAlpha = false
        }
        else if format.hasPrefix("rg8") || format.hasPrefix("rg16") || format.hasPrefix("rg32") || format.hasPrefix("gbgr422") || format.hasPrefix("bgrg422") {
            usage = .color
            channels = 2
            includesAlpha = false
        }
        else if format.hasPrefix("b5g6r5") || format.hasPrefix("rg11b10") || format.hasPrefix("bgr10") {
            usage = .color
            channels = 3
            includesAlpha = false
        }
        else if format.hasPrefix("a1bgr5") || format.hasPrefix("abgr4") || format.hasPrefix("bgr5A1") || format.hasPrefix("bgra8") || format.hasPrefix("rgb10a2") || format.hasPrefix("rgb9e5Float") || format.hasPrefix("bgr10a2") {
            usage = .color
            channels = 4
            includesAlpha = true
        }

        else if format.hasPrefix("a8") {
            usage = .color
            channels = 1
            includesAlpha = true
        }
        else if format.hasPrefix("depth8") || format.hasPrefix("depth16") || format.hasPrefix("depth32") {
            usage = .depth
            channels = 1
            includesAlpha = false
        }
        else if format.hasPrefix("stencil8") || format.hasPrefix("stencil16") {
            usage = .stencil
            channels = 1
            includesAlpha = false
        }
        else if format == "depth24Unorm_stencil8" {
            usage = .depthAndStencil
            channels = 1
            includesAlpha = false
        }
        else if format == "x32_stencil8" || format == "x24_stencil8" {
            usage = .stencil
            channels = 1
            includesAlpha = false
        }
        else {
            unimplemented()
        }

        let extendedRange: Bool = format.contains("xr")
        self = .init(usage: usage, channels: channels, channelType: channelType, convertsSRGB: convertsSRGB, compressed: false, endianness: .none, includesAlpha: includesAlpha, extendedRange: extendedRange)
    }
}

extension MTLPixelFormat {
    var metadata: PixelFormatMetadata? {
        PixelFormatMetadata(parsing: description)
    }
}
