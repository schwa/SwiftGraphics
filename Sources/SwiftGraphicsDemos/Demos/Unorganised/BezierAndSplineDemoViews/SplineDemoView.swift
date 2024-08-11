import CoreGraphicsSupport
import Shapes2D
import SwiftUI

struct SplineDemoView: View, DemoView {
    @State
    private var points: [CGPoint] = []

    @State
    private var lines: [Line] = []

    @State
    private var spline = Spline(knots: [])

    @State
    private var lastRightMouseDownLocation: CGPoint?

    @State
    private var showComb = false

    var coordinateSpace = CoordinateSpace.named("canvas")

    init() {
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white
                Path(spline).stroke()
                    .contextMenu {
                        Button("Split") {
                            guard let lastRightMouseDownLocation else {
                                return
                            }
                            if let spline = spline.split(at: lastRightMouseDownLocation) {
                                self.spline = spline
                            }
                        }
                    }

                if showComb {
                    Path(spline.comb).stroke()
                }

                ForEach(spline.knots.indexed(), id: \.index) { index, knot in
                    Path.line(from: knot.position, to: knot.absoluteControlPointA).stroke(Color.red, style: .init(dash: [5, 5]))
                    Path.line(from: knot.position, to: knot.absoluteControlPointB).stroke(Color.green, style: .init(dash: [5, 5]))
                    if !knot.controlPointA.isZero {
                        Handle($spline.knots[index].absoluteControlPointA)
                        Handle($spline.knots[index].absoluteControlPointB)
                    }
                    Handle($spline.knots[index].position)
                        .contextMenu {
                            Button("Delete") {
                                spline.knots.remove(at: index)
                            }
                            Button("Make Independent") {
                                spline.knots[index] = .init(position: knot.position, controlPoint: .split(knot.controlPointA, -knot.controlPointA))
                            }
                        }
                }
                ForEach(points.indexed(), id: \.index) { index, _ in
                    Handle($points[index])
                }
                ForEach(lines.indexed(), id: \.index) { index, line in
                    if let segment = line.lineSegment(bounds: proxy.frame(in: .local)) {
                        Path(segment).stroke()
                            .lineManipulator(line: $lines[index])
                    }
                }
            }
            .splineTool($spline)
            .contextMenu {
                Button("Add Knot") {
                    let location = lastRightMouseDownLocation ?? CGPoint(proxy.size) / 2
                    spline.knots.append(.init(position: location))
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
                Button("Clear") {
                    lines = []
                    points = []
                    spline = Spline()
                }
            }
            #if os(macOS)
            .lastRightMouseDownLocation($lastRightMouseDownLocation, coordinateSpace: coordinateSpace)
            #endif
            .coordinateSpace(name: coordinateSpace)
        }
        .toolbar {
            Toggle("Show Comb", isOn: $showComb)
        }
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
                spline.knots.append(.init(position: value.location))
            }
            .onDragGesture { value in
                if dragging == false {
                    spline.knots.append(.init(position: value.location))
                    dragging = true
                } else {
                    spline.knots[relative: -1].absoluteControlPointA = value.location
                }
            }
            onEnded: { _ in
                dragging = false
            }
    }
}

extension View {
    func splineTool(_ spline: Binding<Spline>) -> some View {
        modifier(SplineToolModifier(spline: spline))
    }
}

struct LineManipulatorModifier: ViewModifier {
    @Binding
    var line: Line

    @State
    var isHovering = false

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
                        Handle($p1.unsafeBinding())
                        Handle($p2.unsafeBinding())
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
                .onAppear {
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
            .onChanged { _ in
            }
            .onEnded { _ in
            }
    }
}

extension View {
    func lineManipulator(line: Binding<Line>) -> some View {
        modifier(LineManipulatorModifier(line: line))
    }
}

extension [LineSegment]: @retroactive PathConvertible {
    public var path: Path {
        Path(lineSegments: map { ($0.start, $0.end) })
    }
}
