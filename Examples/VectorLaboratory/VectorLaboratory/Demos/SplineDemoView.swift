import SwiftUI
import CoreGraphicsSupport
import Shapes2D


struct SplineDemoView: View, DefaultInitializableView {

    @State
    var points: [CGPoint] = []

    @State
    var lines: [Line] = []

    @State
    var spline = Spline(knots: [])

    @State
    var lastRightMouseDownLocation: CGPoint?

    var coordinateSpace = CoordinateSpace.named("canvas")

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white
                Path.spline(spline).stroke()
                ForEach(spline.knots.indexed(), id: \.index) { (index, knot) in
                    Path.line(from: knot.position, to: knot.position + knot.controlPoint).stroke(Color.red)
                    Path.line(from: knot.position, to: knot.position + knot.inverseControlPoint).stroke(Color.green)
                    if !knot.controlPoint.isZero {
                        Handle($spline.knots[index].absoluteControlPoint)
                        Handle($spline.knots[index].absoluteInverseControlPoint)
                    }
                    Handle($spline.knots[index].position)
                }
//                ForEach(points.indexed(), id: \.index) { (index, point) in
//                    Handle($points[index])
//                }
//                ForEach(lines.indexed(), id: \.index) { (index, line) in
//                    if let segment = line.lineSegment(bounds: proxy.frame(in: .local)) {
//                        Path(segment).stroke()
//                        .lineManipulator(line: $lines[index])
//                    }
//                }
            }
            .splineTool($spline)
//            .onSpatialTapGesture { value in
//                points.append(value.location)
//            }
            .contextMenu {
                Button("Add Knot") {
                    let location = lastRightMouseDownLocation ?? CGPoint(proxy.size) / 2
                    spline.knots.append(.init(position: location, controlPoint: location))
                }
                Button("Add Point") {
                    let location = lastRightMouseDownLocation ?? CGPoint(proxy.size) / 2
                    points.append(location)
                }
                Button("Add Horizontal Line") {
                    let location = lastRightMouseDownLocation ?? CGPoint(proxy.size) / 2
                    lines.append(Line(point: location, angle: .zero))
                }
                Button("Add Vertical Line") {
                    let location = lastRightMouseDownLocation ?? CGPoint(proxy.size) / 2
                    lines.append(Line(point: location, angle: .degrees(90)))
                }
            }
            .lastRightMouseDownLocation($lastRightMouseDownLocation, coordinateSpace: coordinateSpace)
            .coordinateSpace(name: coordinateSpace)
        }
    }
}

extension Path {
    static func spline(_ spline: Spline) -> Path {
        Path { path in
            for (index, knots) in spline.knots.adjacentPairs().enumerated() {
                if path.isEmpty {
                    path.move(to: knots.0.position)
                }
                path.addCurve(
                    to: knots.1.position,
                    control1: index.isEven ? knots.0.absoluteControlPoint : knots.0.absoluteInverseControlPoint,
                    control2: index.isEven ? knots.1.absoluteControlPoint : knots.1.absoluteInverseControlPoint
                )
            }
        }
    }
}

extension Int {
    var isEven: Bool {
        self % 2 == 0
    }
}

struct SplineToolModifier: ViewModifier {

    @Binding
    var spline: Spline

    @State
    var dragging = false

    func body(content: Content) -> some View {
        content
        .onSpatialTapGesture { value in
            spline.knots.append(.init(position: value.location, controlPoint: .zero))
        }
        .onDragGesture { value in
            if dragging == false {
                spline.knots.append(.init(position: value.location, controlPoint: .zero))
                dragging = true
            }
            else {
                spline.knots[relative: -1].absoluteControlPoint = value.location
            }
        }
        onEnded: { value in
            dragging = false
        }
    }
}

extension View {
    func onDragGesture(onChanged: @escaping (DragGesture.Value) -> Void, onEnded: @escaping (DragGesture.Value) -> Void) -> some View {
        gesture(DragGesture().onChanged(onChanged).onEnded(onEnded))
    }
}

extension View {
    func splineTool(_ spline: Binding<Spline>) -> some View {
        modifier(SplineToolModifier(spline: spline))
    }
}

struct Spline {
    struct Knot {
        var position: CGPoint
        var controlPoint: CGPoint
    }

    var knots: [Knot]
}

extension Spline.Knot {

    var absoluteControlPoint: CGPoint {
        get {
            position + controlPoint
        }
        set {
            controlPoint = newValue - position
        }
    }

    var absoluteInverseControlPoint: CGPoint {
        get {
            position + inverseControlPoint
        }
        set {
            inverseControlPoint = newValue - position
        }
    }

    var inverseControlPoint: CGPoint {
        get {
            -controlPoint
        }
        set {
            controlPoint = -newValue
        }
    }
}


extension View {
    func onSpatialTapGesture(count: Int = 1, coordinateSpace: CoordinateSpace = .local, _ ended: @escaping (SpatialTapGesture.Value) -> Void) -> some View {
        gesture(SpatialTapGesture(count: count, coordinateSpace: coordinateSpace).onEnded(ended))
    }
}

struct LineManipulatorModifier: ViewModifier {

    @Binding
    var line: Line

    @State
    var isHovering: Bool = false

    @State
    var p1: CGPoint?

    @State
    var p2: CGPoint?

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            if let segment = line.lineSegment(bounds: proxy.frame(in: .local)) {
                ZStack {
                    content
                    if isHovering == true, p1 != nil, p2 != nil {
                        Handle(self.$p1.unsafeBinding())
                        Handle(self.$p2.unsafeBinding())
                    }
                }
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        isHovering = line.contains(location, tolerance: 10)

                    case .ended:
                        isHovering = false
                    }
                }
                .onAppear() {
                    p1 = lerp(from: segment.start, to: segment.end, by: 1 / 3)
                    p2 = lerp(from: segment.start, to: segment.end, by: 2 / 3)
                }
                .onChange(of: p1) {
                    guard let p1, let p2 else {
                        return
                    }
                    line = Line(points: (p1, p2))
                }
                .onChange(of: p2) {
                    guard let p1, let p2 else {
                        return
                    }
                    line = Line(points: (p1, p2))
                }
            }
        }
    }

    func drag() -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
        .onChanged { value in
            print(value)
        }
        .onEnded { value in
        }
    }
}

extension View {
    func lineManipulator(line: Binding<Line>) -> some View {
        modifier(LineManipulatorModifier(line: line))
    }
}

extension Array {
    subscript(relative index: Int) -> Element {
        get {
            if index >= 0 {
                return self[index]
            }
            else {
                return self[count + index]
            }
        }
        set {
            if index >= 0 {
                self[index] = newValue
            }
            else {
                self[count + index] = newValue
            }

        }
    }
}
