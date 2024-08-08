import Constraints3D
import Projection
import simd
import SIMDSupport
import SwiftUI

public struct CameraRotationWidget: View {
    @Binding
    var rotation: Rotation

    @State
    private var cameraTransform: Transform = .identity

    @State
    private var isHovering = false

    var length: Float = 0.75

    public init(rotation: Binding<Rotation>) {
        self._rotation = rotation
    }

    public var body: some View {
        GeometryReader { proxy in
            let cameraProjection = Projection.orthographic(.init(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1))
            let projectionHelper = Projection3DHelper(size: proxy.size, cameraProjection: cameraProjection, cameraTransform: cameraTransform)
            ZStack {
                Canvas { context, _ in
                    context.draw3DLayer(projection: projectionHelper) { _, context3D in
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
                        rotation.rollPitchYaw.setAxis(info.vector)
                    }
                    .buttonStyle(CameraWidgetButtonStyle())
                    .backgroundStyle(info.color)
                    .offset(projectionHelper.worldSpaceToScreenSpace(info.vector * length))
                    .zIndex(Double(projectionHelper.worldSpaceToClipSpace(info.vector * length).z))
                    .keyboardShortcut(info.keyboardShortcut)
                }
            }
            .onChange(of: rotation, initial: true) {
                cameraTransform.rotation = rotation
                print(cameraTransform)
            }
            .onChange(of: cameraTransform, initial: true) {
                rotation = cameraTransform.rotation
            }
            .modifier(NewBallControllerViewModifier(constraint: .init(radius: 0), transform: $cameraTransform))
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

public extension Axis3D {
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

extension RollPitchYaw {
    mutating func setAxis(_ vector: SIMD3<Float>) {
        switch vector {
        case [-1, 0, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(0), yaw: .degrees(90))
        case [1, 0, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(0), yaw: .degrees(270))
        case [0, -1, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(90), yaw: .degrees(0))
        case [0, 1, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(270), yaw: .degrees(0))
        case [0, 0, -1]:
            self = .init(roll: .degrees(0), pitch: .degrees(180), yaw: .degrees(0))
        case [0, 0, 1]:
            self = .init(roll: .degrees(0), pitch: .degrees(0), yaw: .degrees(0))
        default:
            break
        }
    }
}