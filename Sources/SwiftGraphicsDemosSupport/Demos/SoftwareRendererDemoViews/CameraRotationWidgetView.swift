import Projection
import simd
import SIMDSupport
import SwiftUI

struct CameraRotationWidgetView: View {
    @Binding
    var ballConstraint: BallConstraint

    @State
    var camera = LegacyCamera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .orthographic(.init(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)))

    @State
    var isHovering = false

    var length: Float = 0.75

    init(ballConstraint: Binding<BallConstraint>) {
        self._ballConstraint = ballConstraint
    }

    var body: some View {
        GeometryReader { proxy in
            let projection = Projection3D(size: proxy.size, camera: camera)
            ZStack {
                Canvas { context, _ in
                    context.draw3DLayer(projection: projection) { _, context3D in
                        for axis in Axis.allCases {
                            context3D.stroke(path: Path3D { path in
                                path.move(to: axis.vector * -length)
                                path.addLine(to: axis.vector * length)
                            }, with: .color(axis.color), lineWidth: 2)
                        }
                    }
                }
                .zIndex(-.greatestFiniteMagnitude)

                ForEach(axesInfo(), id: \.0) { info in
                    Button("-\(info.label)") {
                        ballConstraint.rollPitchYaw.setAxis(info.vector)
                    }
                    .buttonStyle(CameraWidgetButtonStyle())
                    .backgroundStyle(info.color)
                    .offset(projection.project(info.vector * length))
                    .zIndex(Double(projection.worldSpaceToClipSpace(info.vector * length).z))
                    .keyboardShortcut(info.keyboardShortcut)
                }
            }
            .onChange(of: ballConstraint, initial: true) {
                camera.transform.matrix = ballConstraint.transform
            }
            .ballRotation($ballConstraint.rollPitchYaw)
            .background(isHovering ? .white.opacity(0.5) : .clear)
            .onHover { isHovering = $0 }
        }
    }

    func axesInfo() -> [(label: String, longLabel: String, color: Color, keyboardShortcut: KeyboardShortcut?, vector: SIMD3<Float>)] {
        [
            ("+\(Axis.x)", "right", Axis.x.color, KeyboardShortcut("3", modifiers: .command), Axis.x.vector * 1),
            ("-\(Axis.x)", "left", Axis.x.color, nil, Axis.x.vector * -1),
            ("+\(Axis.y)", "top", Axis.y.color, KeyboardShortcut("7", modifiers: .command), Axis.y.vector * 1),
            ("-\(Axis.y)", "bottom", Axis.y.color, nil, Axis.y.vector * -1),
            ("+\(Axis.z)", "front", Axis.z.color, KeyboardShortcut("1", modifiers: .command), Axis.z.vector * 1),
            ("-\(Axis.z)", "back", Axis.z.color, nil, Axis.z.vector * -1),
        ]
    }
}

struct CameraWidgetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(2)
            .background {
                Circle().fill(.background)
                    .opacity(configuration.isPressed ? 0.5 : 1.0)
            }
    }
}

enum Axis: CaseIterable {
    case x
    case y
    case z

    var vector: SIMD3<Float> {
        switch self {
        case .x:
            [1, 0, 0]
        case .y:
            [0, 1, 0]
        case .z:
            [0, 0, 1]
        }
    }

    var color: Color {
        switch self {
        case .x:
                .red
        case .y:
                .green
        case .z:
                .blue
        }
    }
}
