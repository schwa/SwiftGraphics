import CoreGraphicsSupport
import Metal
import MetalKit
import MetalSupport
import RenderKit
import Shapes3D
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

struct SceneGraphMapView: View {
    @Binding
    var scene: SceneGraph

    var drawableSize: SIMD2<Float>

    let scale: CGFloat = 10

    var body: some View {
        Canvas(opaque: true) { context, size in
            context.concatenate(CGAffineTransform.translation(CGPoint(size.width / 2, size.height / 2)))

            let helper = try! SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
            for element in helper.elements() {
                let position = CGPoint(element.node.transform.translation.xz)
                switch element.node.content {
                case let camera as Camera:
                    switch camera.projection {
                    case .perspective(let perspective):
                        // TODO: This is showing fovY but it should be fovX
                        let viewCone = Path.arc(center: position * scale, radius: 4 * scale, midAngle: .radians(Double(element.node.heading.radians)), width: .radians(Double(perspective.verticalAngleOfView.radians)))
                        // context.fill(viewCone, with: .radialGradient(Gradient(colors: [.white.opacity(0.5), .white.opacity(0.0)]), center: position * scale, startRadius: 0, endRadius: 4 * scale))
                        context.stroke(viewCone, with: .color(.white))
                    default:
                        break
                    }
                    var cameraImage = context.resolve(Image(systemName: "camera.circle.fill"))
                    cameraImage.shading = .color(.mint)
                    context.draw(cameraImage, at: position * scale, anchor: .center)

                    let targetPosition = position + CGPoint(element.node.target.xz)
                    var targetImage = context.resolve(Image(systemName: "scope"))
                    targetImage.shading = .color(.white)
                    context.draw(targetImage, at: targetPosition * scale, anchor: .center)
                case let geometry as Geometry:
                    let path = Path(ellipseIn: CGRect(center: position * scale, radius: 5))



                    context.stroke(path, with: .color(.red))
                case nil:
                    break
                default:
                    context.draw(Text("?"), at: position * scale)
                }
            }
        }
        .background(.black)
    }
}
