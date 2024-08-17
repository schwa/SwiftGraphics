import Combine
import MetalKit
import ModelIO
import os.log
import simd
import SwiftUI

public extension Bundle {
    static let renderKitShaders: Bundle = {
        if let shadersBundleURL = Bundle.main.url(forResource: "SwiftGraphics_RenderKitShaders", withExtension: "bundle"), let bundle = Bundle(url: shadersBundleURL) {
            return bundle
        }
        // Fail.
        fatalError("Could not find shaders bundle")
    }()
}
