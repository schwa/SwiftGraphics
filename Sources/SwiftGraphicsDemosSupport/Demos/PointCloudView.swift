import SwiftUI
import RenderKit

struct PointCloudView: View, DemoView {
    var body: some View {
        RenderView(renderPasses: [PointCloudRenderPass()])
        .renderContext(try! .init(device: MTLCreateSystemDefaultDevice()!))
    }
}

struct PointCloudRenderPass: RenderPassProtocol {

    var id: AnyHashable = "PointCloudRenderPass"

    struct State: RenderPassState {

    }

    func setup(context: Context, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        State()
    }

    func encode(context: Context, state: State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {

    }

}
