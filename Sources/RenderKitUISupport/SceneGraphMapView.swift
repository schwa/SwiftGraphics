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
    private var scale: Double = 10

    let drawableSize: SIMD2<Float>

    public init(scene: Binding<SceneGraph>, scale: CGFloat = 10, drawableSize: SIMD2<Float>) {
        self._scene = scene
        self.scale = scale
        self.drawableSize = drawableSize
    }

    public var body: some View {
        VStack {
            ZStack {
                let helper = SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
                ForEach(Array(helper.elements()), id: \.node.id) { element in
                    let position = CGPoint(element.node.transform.translation.xz)
                    let view = view(for: element.node)
                    view.offset(position * scale)
                }
            }
            .frame(width: 480, height: 320)

            HStack {
                Button("-") {
                    scale = max(scale - 1, 1)
                }
                TextField("Scale", value: $scale, format: .number)
                    .labelsHidden()
                    .frame(maxWidth: 30)
                Button("+") {
                    scale += 1
                }
            }
            .controlSize(.mini)
            .padding(.bottom, 4)
        }
        .background(.black)
    }

    @ViewBuilder
    func view(for node: Node) -> some View {
        switch node.content {
        case let camera as Camera:
            let viewConeRadius = 4 * scale
            ZStack {
                if case let .perspective(perspective) = camera.projection {
                    let heading = node.heading
                    let viewCone = Path.arc(center: .zero, radius: viewConeRadius, midAngle: heading, width: perspective.horizontalAngleOfView(aspectRatio: Double(drawableSize.x / drawableSize.y)))
                    viewCone.stroke(Color.blue).offset(x: viewConeRadius, y: viewConeRadius)
                }
                Image(systemName: "camera.circle.fill").foregroundStyle(.black, .yellow)
                    .gesture(DragGesture().onChanged { value in
                        scene.modify(label: node.label) { node in
                            node?.transform.translation.xz = SIMD2<Float>(value.location / scale)
                        }
                    })
            }
            .frame(width: viewConeRadius * 2, height: viewConeRadius * 2)
            .zIndex(1)
        case nil:
            EmptyView()
        default:
            Image(systemName: "questionmark.circle.fill").foregroundStyle(.black, .yellow)
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
