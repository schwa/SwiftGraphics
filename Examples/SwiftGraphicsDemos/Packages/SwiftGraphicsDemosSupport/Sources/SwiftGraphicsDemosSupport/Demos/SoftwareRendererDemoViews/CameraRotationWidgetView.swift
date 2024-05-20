import SwiftUI
import simd
import SIMDSupport
import Projection

struct CameraRotationWidgetView: View {
   @Binding
   var ballConstraint: BallConstraint

   @State
   var camera = Camera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .orthographic(.init(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)))

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

               ForEach(Axis.allCases, id: \.self) { axis in
                   Button("-\(axis)") {
                       ballConstraint.rollPitchYaw.setAxis(axis.vector * -1)
                   }
                   .buttonStyle(CameraWidgetButtonStyle())
                   .backgroundStyle(axis.color)
                   .offset(projection.project(axis.vector * -length))
                   .zIndex(Double(projection.worldSpaceToClipSpace(axis.vector * length).z))

                   Button("+\(axis)") {
                       ballConstraint.rollPitchYaw.setAxis(axis.vector)
                   }
                   .buttonStyle(CameraWidgetButtonStyle())
                   .backgroundStyle(axis.color)
                   .offset(projection.project(axis.vector * length))
                   .zIndex(Double(projection.worldSpaceToClipSpace(axis.vector * -length).z))
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
