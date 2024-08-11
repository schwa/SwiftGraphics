import BaseSupport
import Constraints3D
import CoreGraphicsSupport
import Metal
import MetalKit
import RenderKitSceneGraph
import SIMDSupport
import SwiftUI

@available(*, deprecated, message: "Deprecated")
public struct SceneGraphMapView: View {
    @Binding
    var scene: SceneGraph

    private var scale: Double

    let drawableSize: SIMD2<Float>

    let coordinateSpace = NamedCoordinateSpace.named("MapCoordinateSpace")

    public init(scene: Binding<SceneGraph>, scale: CGFloat, drawableSize: SIMD2<Float>) {
        self._scene = scene
        self.scale = scale
        self.drawableSize = drawableSize
    }

    public var body: some View {
        ZStack {
            if drawableSize.x != 0 && drawableSize.y != 0 {
                let helper = SceneGraphRenderHelper(scene: scene, renderTargetSize: drawableSize)
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
                .zIndex(1)
        case nil:
            EmptyView()
        default:
            Image(systemName: "questionmark.circle.fill").foregroundStyle(.black, Color(red: 1, green: 0, blue: 1))
                .gesture(dragGesture(for: node))
        }
    }

    func dragGesture(for node: Node) -> some Gesture {
        DragGesture(coordinateSpace: coordinateSpace).onChanged { value in
            do {
                try scene.modify(node: node) { node in
                    node?.transform.translation.xz = SIMD2<Float>(value.location / scale)
                }
            }
            catch {
                fatalError(error)
            }
        }
    }
}

extension Node {
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