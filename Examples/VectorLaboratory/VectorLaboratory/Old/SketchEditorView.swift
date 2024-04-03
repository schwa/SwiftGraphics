import Algorithms
import CoreGraphicsSupport
import Everything
import Observation
import Sketches
import SwiftFormats
import SwiftUI
import Shapes2D

typealias Element = Sketches.Element

struct SketchEditorView: View {
    static let coordinateSpace = NamedCoordinateSpace.named("Sketch")

    @Binding
    var sketch: Sketch

    @State
    var contextMenuLocation: CGPoint?

    @State
    var selection: Set<Element.ID> = []

    var body: some View {
        SketchView(sketch: $sketch, selection: $selection)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
            .lastRightMouseDownLocation($contextMenuLocation)
        #endif
            .toolbar {
                ForEach(shapeTemplates, id: \.0) { name, image, shape in
                    Button(title: "Add \(name)", systemImage: image) {
                        sketch.elements.append(Element(shape: shape))
                    }
                }
            }
            .inspector(isPresented: .constant(true)) {
                ElementsInspectorView(sketch: $sketch, selection: $selection)
            }
    }

    var shapeTemplates: [(String, String, SketchShapeEnum)] {
        [
            ("Line", "line.diagonal", .init(Sketch.LineSegment(start: [50, 50], end: [100, 100]))),
            ("Point", "point.3.filled.connected.trianglepath.dotted", .init(Sketch.Point(position: [50, 50]))),
            ("Rectangle", "rectangle", .init(Sketch.Rectangle(start: [50, 50], end: [100, 100]))),
        ]
    }
}

struct SketchView: View {
    @Binding
    var sketch: Sketch

    @Binding
    var selection: Set<Element.ID>

    @Environment(\.sketchOverlay)
    var sketchOverlay

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .onTapGesture {
                    selection = []
                }
            ForEach(sketch.elements.indexed(), id: \.element.id) { index, _ in
                let element = Binding<Element> {
                    sketch.elements[index]
                } set: { newValue in
                    sketch.elements[index] = newValue
                }
                let selected = Binding<Bool> {
                    selection.contains(element.id)
                } set: { newValue in
                    if newValue {
                        selection.insert(element.id)
                    }
                    else {
                        selection.remove(element.id)
                    }
                }
                ElementView(element: element, selected: selected)
            }
            sketchOverlay
        }
        .coordinateSpace(SketchEditorView.coordinateSpace)
    }
}

struct ElementView: View {
    @Binding
    var element: Element

    @Binding
    var selected: Bool

    var body: some View {
        switch element.shape {
        case .point(let shape):
            shapeView(shape)
        case .lineSegment(let shape):
            shapeView(shape)
        case .rectangle(let shape):
            shapeView(shape)
        }
    }

    func shapeView(_ shape: some SketchShape) -> some View {
        let shape = Binding {
            shape
        } set: { newValue in
            element.shape = .init(newValue)
        }
        return ShapeView(shape: shape, selected: $selected)
    }
}

struct ShapeView<Shape>: View where Shape: SketchShape {
    @Binding
    var shape: Shape

    @Binding
    var selected: Bool

    var body: some View {
        ZStack {
            shape.path.stroke()
                .onTapGesture {
                    selected = true
                }
            HandlesView(handle: $shape.handles, selected: $selected)
        }
    }
}

struct HandlesView<Handle>: View where Handle: HandlesProtocol {
    @Binding
    var handle: Handle

    @Binding
    var selected: Bool

    @State
    var hover = false

    @ViewBuilder
    var body: some View {
        ForEach(Array(handle.positions), id: \.0) { key, position in
            Path.circle(center: position, radius: 2)
                .fill(fillColor)
                .stroke(strokeColor)
                .gesture(dragGesture(key: key))
                .onHover(perform: { hovering in
                    hover = hovering
                })
                .contentShape(Path.circle(center: position, radius: 8))
        }
    }

    func dragGesture(key: Handle.Key) -> some Gesture {
        DragGesture(coordinateSpace: SketchEditorView.coordinateSpace)
            .onChanged { value in
                handle.positions[key] = value.location
            }
    }

    var fillColor: Color {
        if selected {
            Color.accentColor
        }
        else if hover {
            Color.accentColor
        }
        else {
            Color.white
        }
    }

    var strokeColor: Color {
        if hover {
            Color.accentColor
        }
        else {
            Color.clear
        }
    }
}

// MARK: -

struct SketchOverlayKey: EnvironmentKey {
    static var defaultValue: AnyView?
}

extension EnvironmentValues {
    var sketchOverlay: AnyView? {
        get {
            self[SketchOverlayKey.self]
        }
        set {
            self[SketchOverlayKey.self] = newValue
        }
    }
}

extension View {
    func sketchOverlay(@ViewBuilder _ overlay: () -> some View) -> some View {
        environment(\.sketchOverlay, AnyView(overlay()))
    }
}
