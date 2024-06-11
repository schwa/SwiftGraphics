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

extension Bundle {
    @available(*, deprecated, message: "Deprecated")
    static var renderKitShaders: Bundle {
        let url = Bundle.module.bundleURL.appendingPathComponent("../SwiftGraphics_RenderKitShaders.bundle")
        return Bundle(url: url)!
    }
}
