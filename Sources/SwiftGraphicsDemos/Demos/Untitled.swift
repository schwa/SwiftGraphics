import Foundation

extension Bundle {
    static let swiftGraphicsDemosShaders: Bundle = {
        // Step 1. Find the bundle as a child of main bundle.
        if let shadersBundleURL = Bundle.main.url(forResource: "SwiftGraphics_SwiftGraphicsDemosShaders", withExtension: "bundle"), let bundle = Bundle(url: shadersBundleURL) {
            return bundle
        }
        // Step 2. Find the bundle as peer to the current `Bundle.module`
        if let bundle = Bundle(url: Bundle.module.bundleURL.deletingLastPathComponent().appendingPathComponent("RenderKit_SwiftGraphicsDemosShaders.bundle")) {
            return bundle
        }
        // Fail.
        fatalError("Could not find shaders bundle")
    }()


}
