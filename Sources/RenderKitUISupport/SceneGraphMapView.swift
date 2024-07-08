import CoreGraphicsSupport
import GaussianSplatSupport
import Metal
import MetalKit
import MetalSupport
import RenderKit
import SIMDSupport
import SwiftUI

public struct SceneGraphMapView: View {
    @Binding
    var scene: SceneGraph

    @Binding
    var ballConstraint: BallConstraint

    private var scale: Double

    let drawableSize: SIMD2<Float>

    let coordinateSpace = NamedCoordinateSpace.named("MapCoordinateSpace")

    public init(scene: Binding<SceneGraph>, ballConstraint: Binding<BallConstraint>, scale: CGFloat, drawableSize: SIMD2<Float>) {
        self._scene = scene
        self._ballConstraint = ballConstraint
        self.scale = scale
        self.drawableSize = drawableSize
    }

    public var body: some View {
        ZStack {
            if drawableSize.x != 0 && drawableSize.y != 0 {
                let helper = SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
                ForEach(Array(helper.elements()), id: \.node.id) { element in
                    let position = CGPoint(element.node.transform.translation.xz)
                    let view = view(for: element.node)
                    view.offset(position * scale)
                }
                .foregroundColor(.white)
            }
        }
        .coordinateSpace(coordinateSpace)
    }

    @ViewBuilder
    func view(for node: Node) -> some View {
        switch node.content {
        case let camera as Camera:
            Image(systemName: "camera.circle.fill").foregroundStyle(.black, .yellow)
                .border(Color.yellow)
                .frame(width: 32, height: 32)
                .background(alignment: .center) {
                    if case let .perspective(perspective) = camera.projection {
                        let heading = node.heading
                        ZStack {
                            Path.arc(center: .zero, radius: Double(perspective.zClip.upperBound) * scale, midAngle: heading, width: perspective.horizontalAngleOfView(aspectRatio: Double(drawableSize.x / drawableSize.y))).stroke(.white.opacity(0.2))
                            Path.arc(center: .zero, radius: 4 * scale, midAngle: heading, width: perspective.horizontalAngleOfView(aspectRatio: Double(drawableSize.x / drawableSize.y))).stroke(.blue)
                        }
                        .offset(x: 16, y: 16)
                    }
                }
                .border(Color.red)
                .zIndex(1)
                .gesture(cameraDragGesture(for: node))
        case let splats as Splats:
            Image(systemName: "questionmark.circle.fill").foregroundStyle(.black, Color(red: 1, green: 0, blue: 1))
                .frame(width: 32, height: 32)
                .background {
                    let p0 = CGPoint(splats.boundingBox.0.xz) * scale
                    let p1 = CGPoint(splats.boundingBox.1.xz) * scale
                    let bounds = CGRect(
                        origin: p0,
                        size: CGSize(p1 - p0)
                    )
                    Path { path in
                        path.addPath(Path(bounds))
                        path.addLines([CGPoint(x: bounds.minX, y: bounds.minY), CGPoint(x: bounds.maxX, y: bounds.maxY)])
                        path.addLines([CGPoint(x: bounds.minX, y: bounds.maxY), CGPoint(x: bounds.maxX, y: bounds.minY)])
                    }.stroke(Color.red)
                    .offset(x: 16, y: 16)
                }
                .gesture(dragGesture(for: node))
        case nil:
            EmptyView()
        default:
            Image(systemName: "questionmark.circle.fill").foregroundStyle(.black, Color(red: 1, green: 0, blue: 1))
                .gesture(dragGesture(for: node))
        }
    }

    func cameraDragGesture(for node: Node) -> some Gesture {
        DragGesture(coordinateSpace: coordinateSpace).onChanged { value in
            ballConstraint.radius = Float(max(0, value.location.distance(to: CGPoint(ballConstraint.lookAt.xz) * scale) / scale))
        }
    }

    func dragGesture(for node: Node) -> some Gesture {
        DragGesture(coordinateSpace: coordinateSpace).onChanged { value in
            scene.modify(node: node) { node in
                node!.transform.translation.xz = SIMD2<Float>(value.location / scale)
                print(value.location / scale, node!.transform.translation.xz)
            }
        }
    }

    @ViewBuilder
    func canvas() -> some View {
        let helper = SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
        Canvas(opaque: true) { context, size in
            context.concatenate(CGAffineTransform.translation(CGPoint(size.width / 2, size.height / 2)))

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
