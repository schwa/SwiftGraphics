import Constraints3D
import Widgets3D
import Metal
import MetalKit
import RenderKit
import RenderKitSceneGraph
import simd
import SIMDSupport
import SwiftUI
import SwiftUISupport

@available(*, deprecated, message: "Deprecated")
public struct SceneGraphView: View {
    @Binding
    private var scene: SceneGraph

    let passes: [any PassProtocol]

    public init(scene: Binding<SceneGraph>, passes: [any PassProtocol]) {
        self._scene = scene
        self.passes = passes
    }

    public var body: some View {
        RenderView(passes: passes)
    }
}
