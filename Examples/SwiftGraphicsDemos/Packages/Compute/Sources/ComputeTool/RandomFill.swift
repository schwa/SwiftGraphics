import AppKit
import Compute
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import Metal
import MetalSupport
import RenderKit

struct RandomFill {
    let width = 512
    let height = 512
    let device = MTLCreateSystemDefaultDevice()!

    func main() throws {
        let testImage = CGImage.makeTestImage(width: 512, height: 512)!
        let testTexture = try device.newTexture(with: testImage)
        let outImage = testTexture.cgImage()
        try outImage?.write(to: URL(filePath: "/tmp/out.png"))

        testPixelFormats()
        return

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Uint, width: width, height: height, mipmapped: false)
        textureDescriptor.usage = [.shaderWrite]
        textureDescriptor.resourceOptions = .storageModeShared
        guard let bytesPerRow = textureDescriptor.bytesPerRow else {
            fatalError()
        }
        let bufferSize = bytesPerRow * height
        let buffer = device.makeBuffer(length: bufferSize, options: [.storageModeShared])!
        let alignment = device.minimumLinearTextureAlignment(for: textureDescriptor.pixelFormat)
        let texture = buffer.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: bytesPerRow)!

        let compute = try Compute(device: device)

        let library = ShaderLibrary.bundle(.module)

        var randomFillPass = try compute.makePass(function: library.randomFill_uint)
        randomFillPass.arguments.outputTexture = .texture(texture)

        try compute.task { task in
            try task { dispatch in
                try dispatch(pass: randomFillPass, threadgroupsPerGrid: MTLSize(width: width, height: height, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
            }
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)
        assert(texture.depth == 1)

        let data = UnsafeMutableRawBufferPointer(start: buffer.contents(), count: buffer.length)

        let context = CGContext.bitmapContext(data: data, definition: .init(width: texture.width, height: height, pixelFormat: PixelFormat(bitsPerComponent: texture.pixelFormat.bits!, numberOfComponents: 1, alphaInfo: .none, byteOrder: .orderDefault, colorSpace: colorSpace)))!

        let image = context.makeImage()!

        let url = URL(filePath: "/tmp/image.png")
        let destination = try ImageDestination(url: url)
        destination.addImage(image)
        try destination.finalize()

        let displayColorSpace = NSScreen.main!.colorSpace!
        print(displayColorSpace.localizedName)
        print(displayColorSpace.colorSpaceModel)
    }
}

func testPixelFormats() {
    let device = MTLCreateSystemDefaultDevice()!
    for pixelFormat in MTLPixelFormat.allCases {
        guard let pixelFormat2 = PixelFormat(pixelFormat) else {
            continue
        }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: 10, height: 10, mipmapped: false)
        textureDescriptor.usage = [.shaderWrite]
        textureDescriptor.resourceOptions = .storageModeShared
        let alignment = device.minimumLinearTextureAlignment(for: textureDescriptor.pixelFormat)
        guard let unalignedBytesPerRow = textureDescriptor.bytesPerRow else {
            continue
        }
        let bytesPerRow = align(unalignedBytesPerRow, alignment: alignment)
        let bufferSize = bytesPerRow * textureDescriptor.height
        let buffer = device.makeBuffer(length: bufferSize, options: [.storageModeShared])!
        let texture = buffer.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: bytesPerRow)!

        let data = UnsafeMutableRawBufferPointer(start: buffer.contents(), count: buffer.length)
        _ = CGContext.bitmapContext(data: data, definition: .init(width: texture.width, height: texture.height, bytesPerRow: bytesPerRow, pixelFormat: pixelFormat2))!
    }
}

extension MTLPixelFormat: CaseIterable {
    public static var allCases: [MTLPixelFormat] {
        [
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
            .depth24Unorm_stencil8,
            .depth32Float_stencil8,
            .x32_stencil8,
            .x24_stencil8,
        ]
    }
}
