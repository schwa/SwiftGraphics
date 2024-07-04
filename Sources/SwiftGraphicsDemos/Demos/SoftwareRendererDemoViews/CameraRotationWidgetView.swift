import Projection
import simd
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI
import CoreGraphicsSupport

struct CameraRotationWidgetView: View {
    @Binding
    var ballConstraint: BallConstraint

    @State
    private var cameraTransform: Transform = .translation([0, 0, -5])

    @State
    private var cameraProjection: Projection = .orthographic(.init(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1))

    @State
    private var isHovering = false

    var length: Float = 0.75

    init(ballConstraint: Binding<BallConstraint>) {
        self._ballConstraint = ballConstraint
    }

    var body: some View {
        GeometryReader { proxy in
            let projection = Projection3DHelper(size: proxy.size, cameraProjection: cameraProjection, cameraTransform: cameraTransform)
            ZStack {
                Canvas { context, _ in
                    context.draw3DLayer(projection: projection) { _, context3D in
                        for axis in Axis3D.allCases {
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
                    .offset(projection.worldSpaceToScreenSpace(info.vector * length))
                    .zIndex(Double(projection.worldSpaceToClipSpace(info.vector * length).z))
                    .keyboardShortcut(info.keyboardShortcut)
                }
            }
            .onChange(of: ballConstraint, initial: true) {
                cameraTransform = ballConstraint.transform
            }
            .ballRotation($ballConstraint.rollPitchYaw)
            .background(isHovering ? .white.opacity(0.5) : .clear)
            .onHover { isHovering = $0 }
        }
    }

    func axesInfo() -> [(label: String, longLabel: String, color: Color, keyboardShortcut: KeyboardShortcut?, vector: SIMD3<Float>)] {
        [
            ("+\(Axis3D.x)", "right", Axis3D.x.color, KeyboardShortcut("3", modifiers: .command), Axis3D.x.vector * 1),
            ("-\(Axis3D.x)", "left", Axis3D.x.color, nil, Axis3D.x.vector * -1),
            ("+\(Axis3D.y)", "top", Axis3D.y.color, KeyboardShortcut("7", modifiers: .command), Axis3D.y.vector * 1),
            ("-\(Axis3D.y)", "bottom", Axis3D.y.color, nil, Axis3D.y.vector * -1),
            ("+\(Axis3D.z)", "front", Axis3D.z.color, KeyboardShortcut("1", modifiers: .command), Axis3D.z.vector * 1),
            ("-\(Axis3D.z)", "back", Axis3D.z.color, nil, Axis3D.z.vector * -1),
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
