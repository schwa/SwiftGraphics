import CoreGraphicsSupport
import Metal
import MetalKit
import MetalSupport
import RenderKit
import SIMDSupport
import SwiftUI

public struct SceneGraphMapView: View {
    @Binding
    var scene: SceneGraph

    @State
    private var scale: CGFloat = 10

    let drawableSize: SIMD2<Float>

    public init(scene: Binding<SceneGraph>, scale: CGFloat = 10, drawableSize: SIMD2<Float>) {
        self._scene = scene
        self.scale = scale
        self.drawableSize = drawableSize
    }

    public var body: some View {
        Canvas(opaque: true) { context, size in
            context.concatenate(CGAffineTransform.translation(CGPoint(size.width / 2, size.height / 2)))

            let helper = SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
            for element in helper.elements() {
                let position = CGPoint(element.node.transform.translation.xz)
                switch element.node.content {
                case let camera as Camera:
                    switch camera.projection {
                    case .perspective(let perspective):
                        let heading = element.node.heading
                        let viewCone = Path.arc(center: position * scale, radius: 4 * scale, midAngle: heading, width: perspective.horizontalAngleOfView(aspectRatio: Double(drawableSize.x / drawableSize.y)))
                        context.fill(viewCone, with: .radialGradient(Gradient(colors: [.white.opacity(0.5), .white.opacity(0.0)]), center: position * scale, startRadius: 0, endRadius: 4 * scale))
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

extension Node: FirstPersonCameraProtocol {
    var target: SIMD3<Float> {
        get {
            // transform.translation.xz
            .zero
        }
        // swiftlint:disable:next unused_setter_value
        set {
        }
    }

    var heading: Angle {
        get {
            let projectedVector = transform.rotation.apply([0, 0, -1])
            // Calculate the angle using atan2
            // atan2(x, z) because we want angle from positive Z-axis (forward)
            let angle = atan2(projectedVector.x, projectedVector.z)
            // Convert to degrees and normalize to 0-360 range
            var degrees = angle * (180 / .pi)
            if degrees < 0 {
                degrees += 360
            }
            return .degrees(Double(-degrees + 90))
        }
        // swiftlint:disable:next unused_setter_value
        set {
        }
    }
}
