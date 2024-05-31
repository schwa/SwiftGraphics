import Shapes2D
import SwiftUI

enum Tool {
    case select
    case line
    case circle
}

struct SelectTool: ViewModifier {
    @Binding
    var selection: Set<UUID>

    @Binding
    var shapes: [Identified<UUID, MyShape>]

    func body(content: Content) -> some View {
        content.gesture(SpatialTapGesture(coordinateSpace: NamedCoordinateSpace.canvas).onEnded({ value in
            let hits = shapes.filter { shape in
                shape.content.contains(value.location, lineWidth: 8)
            }
            .map(\.id)
            selection = Set(hits)
        }))
        .overlay {
            handles()
        }
    }

    func handles() -> some View {
        ForEach(Array(selection), id: \.self) { id in
            if let index = shapes.firstIndex(identifiedBy: id) {
                let shape = shapes[index].content
                let controlPoints = shape.controlPoints
                ForEach(Array(controlPoints.enumerated()), id: \.0) { controlPointIndex, controlPoint in
                    let binding = Binding {
                        controlPoint
                    } set: { newValue in
                        var controlPoints = controlPoints
                        controlPoints[controlPointIndex] = newValue
                        shapes[index].content.controlPoints = controlPoints
                    }
                    Handle(binding)
                }
            }
        }
    }
}

struct LineTool: ViewModifier {
    @State
    var lastPoint: CGPoint?

    @State
    var currentPoint: CGPoint?

    @Binding
    var editedShape: MyShape?

    var onCommit: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                if let lastPoint, let currentPoint {
                    Path.line(from: lastPoint, to: currentPoint).stroke(.cyan)
                }
            }
            .gesture(SpatialTapGesture(coordinateSpace: NamedCoordinateSpace.canvas).onEnded({ value in
                if lastPoint != nil {
                    onCommit()
                    lastPoint = nil
                }
                else {
                    lastPoint = value.location
                }
            }))
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    currentPoint = location
                    if let lastPoint, let currentPoint {
                        editedShape = .line(.init(lastPoint, currentPoint))
                    }
                default:
                    break
                }
            }
    }
}

struct CircleTool: ViewModifier {
    @Binding
    var editedShape: MyShape?

    var onCommit: () -> Void

    @State
    var center: CGPoint?

    @State
    var currentPoint: CGPoint?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let center, let currentPoint {
                    Path.line(from: center, to: currentPoint).stroke(.cyan)
                    Path.circle(center: center, radius: center.distance(to: currentPoint)).stroke(.cyan)
                }
            }
            .gesture(SpatialTapGesture(coordinateSpace: NamedCoordinateSpace.canvas).onEnded({ value in
                if center != nil {
                    onCommit()
                    center = nil
                }
                else {
                    center = value.location
                }
            }))
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    currentPoint = location
                    if let center, let currentPoint {
                        editedShape = .circle(.init(center: center, radius: center.distance(to: currentPoint)))
                    }
                default:
                    break
                }
            }
    }
}

struct ShapeEditor: View {
    @Binding
    var shape: MyShape

    var body: some View {
        switch shape {
        case .line(let shape):
            let shape = Binding {
                shape
            } set: { newValue in
                self.shape = .line(newValue)
            }
            LineEditor(shape: shape)
        case .circle(let shape):
            let shape = Binding {
                shape
            } set: { newValue in
                self.shape = .circle(newValue)
            }
            CircleEditor(shape: shape)
        }
    }
}

struct LineEditor: View {
    @Binding
    var shape: LineSegment

    var body: some View {
        HStack {
            Text("Line")
            LabeledContent("Start") {
                TextField("start", value: $shape.start, format: .point)
                    .frame(maxWidth: 80)
            }
            LabeledContent("End") {
                TextField("end", value: $shape.end, format: .point)
                    .frame(maxWidth: 80)
            }
            LabeledContent("Length") {
                TextField("length", value: .constant(shape.length), format: .number)
                    .frame(maxWidth: 80)
            }
            LabeledContent("Angle") {
                TextField("angle", value: .constant(shape.angle), format: .angle)
                    .frame(maxWidth: 80)
            }
            Button("Reverse") {
                shape = shape.inverted
            }
        }
    }
}

struct CircleEditor: View {
    @Binding
    var shape: Shapes2D.Circle

    var body: some View {
        HStack {
            Text("Circle")
            LabeledContent("Center") {
                TextField("center", value: $shape.center, format: .point)
                    .frame(maxWidth: 80)
            }
            LabeledContent("Radius") {
                TextField("radius", value: $shape.radius, format: .number)
                    .frame(maxWidth: 80)
            }
        }
    }
}
