import Metal
import MetalKit
import MetalSupport
import RenderKit
import SwiftUI

struct PixelFormatsDemoView: View, DemoView {
    @Environment(\.metalDevice)
    var device

    @State
    var texture: MTLTexture?

    @State
    var convertedTextures: [MTLPixelFormat: MTLTexture] = [:]

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
            fatalError()
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

extension MTLPixelFormat: CaseIterable {
    public static var allCases: [MTLPixelFormat] {
        let baseCases: [MTLPixelFormat] = [
            .invalid,
            .a8Unorm,
            .r8Unorm,
            .r8Unorm_srgb,
            .r8Snorm,
            .r8Uint,
            .r8Sint,
            .r16Unorm,
            .r16Snorm,
            .r16Uint,
            .r16Sint,
            .r16Float,
            .rg8Unorm,
            .rg8Unorm_srgb,
            .rg8Snorm,
            .rg8Uint,
            .rg8Sint,
            .b5g6r5Unorm,
            .a1bgr5Unorm,
            .abgr4Unorm,
            .bgr5A1Unorm,
            .r32Uint,
            .r32Sint,
            .r32Float,
            .rg16Unorm,
            .rg16Snorm,
            .rg16Uint,
            .rg16Sint,
            .rg16Float,
            .rgba8Unorm,
            .rgba8Unorm_srgb,
            .rgba8Snorm,
            .rgba8Uint,
            .rgba8Sint,
            .bgra8Unorm,
            .bgra8Unorm_srgb,
            .rgb10a2Unorm,
            .rgb10a2Uint,
            .rg11b10Float,
            .rgb9e5Float,
            .bgr10a2Unorm,
            .bgr10_xr,
            .bgr10_xr_srgb,
            .rg32Uint,
            .rg32Sint,
            .rg32Float,
            .rgba16Unorm,
            .rgba16Snorm,
            .rgba16Uint,
            .rgba16Sint,
            .rgba16Float,
            .bgra10_xr,
            .bgra10_xr_srgb,
            .rgba32Uint,
            .rgba32Sint,
            .rgba32Float,
            .bc1_rgba,
            .bc1_rgba_srgb,
            .bc2_rgba,
            .bc2_rgba_srgb,
            .bc3_rgba,
            .bc3_rgba_srgb,
            .bc4_rUnorm,
            .bc4_rSnorm,
            .bc5_rgUnorm,
            .bc5_rgSnorm,
            .bc6H_rgbFloat,
            .bc6H_rgbuFloat,
            .bc7_rgbaUnorm,
            .bc7_rgbaUnorm_srgb,
            .pvrtc_rgb_2bpp,
            .pvrtc_rgb_2bpp_srgb,
            .pvrtc_rgb_4bpp,
            .pvrtc_rgb_4bpp_srgb,
            .pvrtc_rgba_2bpp,
            .pvrtc_rgba_2bpp_srgb,
            .pvrtc_rgba_4bpp,
            .pvrtc_rgba_4bpp_srgb,
            .eac_r11Unorm,
            .eac_r11Snorm,
            .eac_rg11Unorm,
            .eac_rg11Snorm,
            .eac_rgba8,
            .eac_rgba8_srgb,
            .etc2_rgb8,
            .etc2_rgb8_srgb,
            .etc2_rgb8a1,
            .etc2_rgb8a1_srgb,
            .astc_4x4_srgb,
            .astc_5x4_srgb,
            .astc_5x5_srgb,
            .astc_6x5_srgb,
            .astc_6x6_srgb,
            .astc_8x5_srgb,
            .astc_8x6_srgb,
            .astc_8x8_srgb,
            .astc_10x5_srgb,
            .astc_10x6_srgb,
            .astc_10x8_srgb,
            .astc_10x10_srgb,
            .astc_12x10_srgb,
            .astc_12x12_srgb,
            .astc_4x4_ldr,
            .astc_5x4_ldr,
            .astc_5x5_ldr,
            .astc_6x5_ldr,
            .astc_6x6_ldr,
            .astc_8x5_ldr,
            .astc_8x6_ldr,
            .astc_8x8_ldr,
            .astc_10x5_ldr,
            .astc_10x6_ldr,
            .astc_10x8_ldr,
            .astc_10x10_ldr,
            .astc_12x10_ldr,
            .astc_12x12_ldr,
            .astc_4x4_hdr,
            .astc_5x4_hdr,
            .astc_5x5_hdr,
            .astc_6x5_hdr,
            .astc_6x6_hdr,
            .astc_8x5_hdr,
            .astc_8x6_hdr,
            .astc_8x8_hdr,
            .astc_10x5_hdr,
            .astc_10x6_hdr,
            .astc_10x8_hdr,
            .astc_10x10_hdr,
            .astc_12x10_hdr,
            .astc_12x12_hdr,
            .gbgr422,
            .bgrg422,
            .depth16Unorm,
            .depth32Float,
            .stencil8,
            .depth32Float_stencil8,
            .x32_stencil8,
        ]

        #if os(macOS)
            return baseCases + [
                .depth24Unorm_stencil8,
                .x24_stencil8,
            ]
        #else
            return baseCases
        #endif
    }
}
