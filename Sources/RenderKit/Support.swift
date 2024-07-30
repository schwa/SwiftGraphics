import Combine
import MetalKit
import ModelIO
import os.log
import simd
import SwiftUI

public extension Bundle {
    static let renderKitShadersLegacy: Bundle = {
        // Step 1. Find the bundle as a child of main bundle.
        if let shadersBundleURL = Bundle.main.url(forResource: "SwiftGraphics_RenderKitShadersLegacy", withExtension: "bundle"), let bundle = Bundle(url: shadersBundleURL) {
            return bundle
        }
        // Step 2. Find the bundle as peer to the current `Bundle.module`
        if let bundle = Bundle(url: Bundle.module.bundleURL.deletingLastPathComponent().appendingPathComponent("RenderKit_RenderKitShadersLegacy.bundle")) {
            return bundle
        }
        // Fail.
        fatalError("Could not find shaders bundle")
    }()

    static let renderKitShaders: Bundle = {
        if let shadersBundleURL = Bundle.main.url(forResource: "SwiftGraphics_RenderKitShaders", withExtension: "bundle"), let bundle = Bundle(url: shadersBundleURL) {
            return bundle
        }
        // Fail.
        fatalError("Could not find shaders bundle")
    }()
}
