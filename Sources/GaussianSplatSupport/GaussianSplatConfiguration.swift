import Metal
#if !targetEnvironment(simulator)
import MetalFX
#endif
import MetalKit
import os
import simd
import SwiftUI

public struct GaussianSplatConfiguration {
    public enum SortMethod {
        case gpuBitonic
        case cpuRadix
    }

    public var debugMode: Bool
    public var metalFXRate: Float
    public var discardRate: Float
    public var clearColor: MTLClearColor
    public var skyboxTexture: MTLTexture?
    public var verticalAngleOfView: Angle
    public var sortMethod: SortMethod
    public var renderSkybox: Bool = true
    public var renderSplats: Bool = true

    public init(debugMode: Bool = false, metalFXRate: Float = 2, discardRate: Float = 0.0, clearColor: MTLClearColor = .init(red: 0, green: 0, blue: 0, alpha: 1), skyboxTexture: MTLTexture? = nil, verticalAngleOfView: Angle = .degrees(90), sortMethod: SortMethod = .cpuRadix) {
        self.debugMode = debugMode
        self.metalFXRate = metalFXRate
        self.discardRate = discardRate
        self.clearColor = clearColor
        self.skyboxTexture = skyboxTexture
        self.verticalAngleOfView = verticalAngleOfView
        self.sortMethod = sortMethod
    }

    @MainActor
    public static func defaultSkyboxTexture(device: MTLDevice) -> MTLTexture? {
        let gradient = LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.4),
                .init(color: Color(red: 135 / 255, green: 206 / 255, blue: 235 / 255), location: 0.5),
                .init(color: Color(red: 135 / 255, green: 206 / 255, blue: 235 / 255), location: 1)
            ],
            startPoint: .init(x: 0, y: 0),
            endPoint: .init(x: 0, y: 1)
        )

        guard var cgImage = ImageRenderer(content: Rectangle().fill(gradient).frame(width: 1024, height: 1024)).cgImage else {
            fatalError("Could not render image.")
        }
        let bitmapInfo: CGBitmapInfo
        if cgImage.byteOrderInfo == .order32Little {
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        } else {
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        }
        cgImage = cgImage.convert(bitmapInfo: bitmapInfo)!

        let textureLoader = MTKTextureLoader(device: device)
        let texture = try! textureLoader.newTexture(cgImage: cgImage, options: nil)
        texture.label = "Skybox Gradient"
        return texture
    }
}
