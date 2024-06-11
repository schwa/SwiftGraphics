import Combine
@preconcurrency import Metal
import MetalKit
import ModelIO
import os.log
import RenderKitShaders
import simd
import SwiftGraphicsSupport
import SwiftUI

public struct RenderContext: Sendable {
    public var logger: Logger?
    public var device: MTLDevice
    public var library: MTLLibrary

    public init(logger: Logger? = nil, device: MTLDevice, library: MTLLibrary) {
        self.logger = logger
        self.device = device
        self.library = library
    }

    @available(*, deprecated, message: "Deprecated")
    public init(logger: Logger? = nil, device: MTLDevice) throws {
        self.logger = logger
        self.device = device
        self.library = try device.makeDebugLibrary(bundle: .renderKitShaders)
    }
}

internal struct RenderContextKey: EnvironmentKey {
    static let defaultValue: RenderContext? = nil
}

public extension EnvironmentValues {
    var renderContext: RenderContext? {
        get {
            self[RenderContextKey.self]
        }
        set {
            self[RenderContextKey.self] = newValue
        }
    }
}

public extension View {
    func renderContext(_ value: RenderContext) -> some View {
        environment(\.renderContext, value)
    }
}

//extension Bundle {
//    static var renderKitShaders: Bundle {
//        let url = Bundle.module.bundleURL.appendingPathComponent("../SwiftGraphics_RenderKitShaders.bundle")
//        return Bundle(url: url)!
//    }
//}

public extension Bundle {
    static let renderKitShaders: Bundle = {
        // Step 1. Find the bundle as a child of main bundle.
        if let shadersBundleURL = Bundle.main.url(forResource: "SwiftGraphics_RenderKitShaders", withExtension: "bundle"), let bundle = Bundle(url: shadersBundleURL) {
            return bundle
        }
        // Step 2. Find the bundle as peer to the current `Bundle.module`
        if let bundle = Bundle(url: Bundle.module.bundleURL.deletingLastPathComponent().appendingPathComponent("RenderKit_RenderKitShaders.bundle")) {
            return bundle
        }
        // Fail.
        fatalError("Could not find shaders bundle")
    }()
}
