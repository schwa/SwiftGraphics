import CoreGraphicsSupport
import simd
import SIMDSupport
import SwiftUI

struct SimpleSceneMapView: View {
    @Binding
    var scene: SimpleScene

    let scale: CGFloat = 10

    var body: some View {
        Canvas(opaque: true) { context, size in
            context.concatenate(CGAffineTransform.translation(CGPoint(size.width / 2, size.height / 2)))
            for model in scene.models {
                let position = CGPoint(model.transform.translation.xz)
                let colorVector = (model.material as? FlatMaterial)?.baseColorFactor ?? [1, 0, 0, 1]
                let color = Color(red: Double(colorVector.r), green: Double(colorVector.g), blue: Double(colorVector.b))
                context.fill(Path(ellipseIn: CGRect(center: position * scale, radius: 0.5 * scale)), with: .color(color.opacity(0.5)))
            }
            let cameraPosition = CGPoint(scene.camera.transform.translation.xz)

            if case .perspective(let perspective) = scene.camera.projection {
                // TODO: This is showing fovY but it should be fovX
                let viewCone = Path.arc(center: cameraPosition * scale, radius: 4 * scale, midAngle: .radians(Double(scene.camera.heading.radians)), width: .radians(Double(perspective.fovy.radians)))
                    // context.fill(viewCone, with: .radialGradient(Gradient(colors: [.white.opacity(0.5), .white.opacity(0.0)]), center: cameraPosition * scale, startRadius: 0, endRadius: 4 * scale))
                context.stroke(viewCone, with: .color(.white))
            }

            var cameraImage = context.resolve(Image(systemName: "camera.circle.fill"))
            cameraImage.shading = .color(.mint)
            context.draw(cameraImage, at: cameraPosition * scale, anchor: .center)

            let lightPosition = CGPoint(scene.light.position.translation.xz)
            var lightImage = context.resolve(Image(systemName: "lightbulb.fill"))
            lightImage.shading = .color(.yellow)
            context.draw(lightImage, at: lightPosition * scale, anchor: .center)

            let targetPosition = cameraPosition + CGPoint(scene.camera.target.xz)
            var targetImage = context.resolve(Image(systemName: "scope"))
            targetImage.shading = .color(.white)
            context.draw(targetImage, at: targetPosition * scale, anchor: .center)
        }
        .background(.black)
    }
}
