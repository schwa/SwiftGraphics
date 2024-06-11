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

    let scale: CGFloat = 10

    var body: some View {
        Canvas(opaque: true) { context, size in
            context.concatenate(CGAffineTransform.translation(CGPoint(size.width / 2, size.height / 2)))
//            for model in scene.models {
//                let position = CGPoint(model.transform.translation.xz)
//                let colorVector = (model.material as? FlatMaterial)?.baseColorFactor ?? [1, 0, 0, 1]
//                let color = Color(red: Double(colorVector.r), green: Double(colorVector.g), blue: Double(colorVector.b))
//                context.fill(Path(ellipseIn: CGRect(center: position * scale, radius: 0.5 * scale)), with: .color(color.opacity(0.5)))
//            }
            if let cameraNode = scene.currentCameraNode, let camera = cameraNode.content?.camera {
                let cameraPosition = CGPoint(cameraNode.transform.translation.xz)

                switch camera.projection {
                case .perspective(let perspective):
                    // TODO: This is showing fovY but it should be fovX
                    let viewCone = Path.arc(center: cameraPosition * scale, radius: 4 * scale, midAngle: .radians(Double(cameraNode.heading.radians)), width: .radians(Double(perspective.verticalAngleOfView.radians)))
                    // context.fill(viewCone, with: .radialGradient(Gradient(colors: [.white.opacity(0.5), .white.opacity(0.0)]), center: cameraPosition * scale, startRadius: 0, endRadius: 4 * scale))
                    context.stroke(viewCone, with: .color(.white))
                default:
                    fatalError()
                }

                var cameraImage = context.resolve(Image(systemName: "camera.circle.fill"))
                cameraImage.shading = .color(.mint)
                context.draw(cameraImage, at: cameraPosition * scale, anchor: .center)

                let targetPosition = cameraPosition + CGPoint(cameraNode.target.xz)
                var targetImage = context.resolve(Image(systemName: "scope"))
                targetImage.shading = .color(.white)
                context.draw(targetImage, at: targetPosition * scale, anchor: .center)
            }

//            let lightPosition = CGPoint(scene.light.position.translation.xz)
//            var lightImage = context.resolve(Image(systemName: "lightbulb.fill"))
//            lightImage.shading = .color(.yellow)
//            context.draw(lightImage, at: lightPosition * scale, anchor: .center)

        }
        .background(.black)
    }
}
