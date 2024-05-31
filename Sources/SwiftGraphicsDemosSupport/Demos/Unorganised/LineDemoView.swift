import CoreGraphicsSupport
import Shapes2D
import SwiftFormats
import SwiftUI

struct LineDemoView: View, DemoView {
    struct Element: Identifiable, Codable {
        var id: String = UUID().uuidString
        var lineSegment: LineSegment
        var color: Color
    }

    @CodableAppStorage("KEY")
    var elements: [Element] = [
        .init(id: "1", lineSegment: .init(1, 1, 4, 4), color: .orange),
        .init(id: "2", lineSegment: .init(1, 4, 4, 1), color: .indigo),
    ]

    @CodableAppStorage("SELECTION")
    var selectedElement: Element.ID?

    @State
    var showIntercepts = true

    @State
    var showIntersections = true

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let size = proxy.size
                let transform: CGAffineTransform = .translation(x: 2, y: 2) * .scale(x: 100, y: 100) * .scale(x: 1, y: -1) * .translation(x: 0, y: size.height)
                AxisView(transform: transform)
                    .onTapGesture {
                        selectedElement = nil
                    }
                ForEach(elements) { element in
                    let lineSegment = element.lineSegment
                    let line = Line(points: (lineSegment.start, lineSegment.end))
                    // TODO: stop hardcoding bounds
                    if let clippedLine = line.lineSegment(bounds: CGRect(x: -20, y: -20, width: 40, height: 40)) {
                        Path.line(from: clippedLine.start, to: clippedLine.end).applying(transform).stroke(lineWidth: 5).foregroundColor(element.color.opacity(0.25))
                            .onTapGesture {
                                selectedElement = element.id
                            }
                    }

                    if selectedElement == element.id {
                        Path.line(from: lineSegment.start, to: lineSegment.end).applying(transform)
                            .stroke(lineWidth: 9)
                            .foregroundColor(.accentColor)
                        Path.line(from: lineSegment.start, to: lineSegment.end).applying(transform)
                            .stroke(lineWidth: 6)
                            .foregroundColor(.white)
                    }

                    Path.line(from: lineSegment.start, to: lineSegment.end).applying(transform)
                        .stroke(lineWidth: 5)
                        .foregroundColor(element.color)
                        .onTapGesture {
                            selectedElement = element.id
                        }
                }
                ForEach(elements) { element in
                    let start = Binding {
                        element.lineSegment.start
                    } set: { newValue in
                        elements[elements.firstIndex(identifiedBy: element.id)!].lineSegment.start = newValue.map { floor($0 / 0.25) * 0.25 }
                    }
                    let end = Binding {
                        element.lineSegment.end
                    } set: { newValue in
                        elements[elements.firstIndex(identifiedBy: element.id)!].lineSegment.end = newValue.map { floor($0 / 0.25) * 0.25 }
                    }
                    Handle(start.transformed(transform))
                        .simultaneousGesture(TapGesture().onEnded({ selectedElement = element.id }))
                    Handle(end.transformed(transform))
                        .simultaneousGesture(TapGesture().onEnded({ selectedElement = element.id }))
                }
                Canvas { context, _ in
                    for (index, lhs) in elements.enumerated() {
                        let lhsLine = Line(points: (lhs.lineSegment.start, lhs.lineSegment.end))

                        if showIntercepts {
                            if let xIntercept = lhsLine.xIntercept {
                                context.fill(Path.circle(center: xIntercept, radius: 0.06), with: .color(.white), transform: transform)
                                context.fill(Path.circle(center: xIntercept, radius: 0.05), with: .color(.red), transform: transform)
                            }
                            if let yIntercept = lhsLine.yIntercept {
                                context.fill(Path.circle(center: yIntercept, radius: 0.06), with: .color(.white), transform: transform)
                                context.fill(Path.circle(center: yIntercept, radius: 0.05), with: .color(.green), transform: transform)
                            }
                        }

                        if showIntersections {
                            for rhs in elements.dropFirst(index + 1) {
                                let rhsLine = Line(points: (rhs.lineSegment.start, rhs.lineSegment.end))
                                if case .point(let point) = Line.intersection(lhsLine, rhsLine) {
                                    context.fill(Path.circle(center: point, radius: 0.06), with: .color(.white), transform: transform)
                                    context.fill(Path.circle(center: point, radius: 0.05), with: .color(.blue), transform: transform)
                                }
                            }
                        }
                    }
                }
                .allowsHitTesting(false)
            }
            .inspector(isPresented: .constant(true)) {
                if let selectedElement, let element = elements.first(identifiedBy: selectedElement) {
                    let binding = Binding {
                        element
                    } set: { newValue in
                        elements[elements.firstIndex(identifiedBy: element.id)!] = newValue
                    }
                    Form {
                        LabeledContent("ID", value: element.id)
                        ColorPicker("Color", selection: binding.color)
                        LineSegmentInfoView(lineSegment: binding.lineSegment)
                    }
                }
            }
        }
        .toolbar {
            Toggle("Show Intercepts", isOn: $showIntercepts)
            Toggle("Show Intersecitons", isOn: $showIntersections)
            Button("Add line") {
                elements.append(.init(lineSegment: .init(0, 0, 1, 1), color: .blue))
            }
            Button("Delete line") {
                guard let selectedElement, let index = elements.firstIndex(identifiedBy: selectedElement) else {
                    return
                }
                elements.remove(at: index)
            }
            .disabled(selectedElement == nil)
        }
    }
}

// MARK: -

struct AxisView: View {
    var transform: CGAffineTransform

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size).applying(transform.inverted())
            drawRules(context: context, bounds: bounds, distance: 0.25, shading: .color(.black.opacity(0.05)))
            drawRules(context: context, bounds: bounds, distance: 1.0, shading: .color(.black.opacity(0.2)))
            let d = 1.0
            for x: Double in stride(from: floor(bounds.minX / d) * d, through: bounds.maxX, by: d) {
                context.draw(Text(x, format: .number), at: CGPoint(x: x, y: 0).applying(transform) - CGPoint(x: 10, y: -10))
            }
            for y: Double in stride(from: floor(bounds.minY / d) * d, through: bounds.maxY, by: d) {
                context.draw(Text(y, format: .number), at: CGPoint(x: 0, y: y).applying(transform) - CGPoint(x: 10, y: -10))
            }
        }
    }

    func drawRules(context: GraphicsContext, bounds: CGRect, distance d: Double, shading: GraphicsContext.Shading) {
        for x: Double in stride(from: floor(bounds.minX / d) * d, through: bounds.maxX, by: d) {
            if let segment = Line.vertical(x: x).lineSegment(bounds: bounds) {
                let path = Path.line(from: segment.start, to: segment.end)
                context.stroke(path, with: shading, lineWidth: 1, transform: transform)
            }
        }
        for y: Double in stride(from: floor(bounds.minY / d) * d, through: bounds.maxY, by: d) {
            if let segment = Line.horizontal(y: y).lineSegment(bounds: bounds) {
                let path = Path.line(from: segment.start, to: segment.end)
                context.stroke(path, with: shading, lineWidth: 1, transform: transform)
            }
        }
    }
}

// MARK: -

struct LineSegmentInfoView: View {
    @Binding
    var lineSegment: LineSegment

    var body: some View {
        Section("Line Segment") {
            TextField("Start", value: $lineSegment.start, format: .point)
            TextField("End", value: $lineSegment.end, format: .point)
            LabeledContent("Length", value: lineSegment.length, format: .number)
        }
        let line1 = Line(points: (lineSegment.start, lineSegment.end))
        //                    LabeledContent("Angle", value: line.angle, format: .angle)
        Section("Line (Standard form)") {
            LabeledContent("a", value: line1.a, format: .number)
            LabeledContent("b", value: line1.b, format: .number)
            LabeledContent("c", value: line1.c, format: .number)
            LabeledContent("isHorizontal", value: line1.isHorizontal, format: .bool)
            LabeledContent("isVertical", value: line1.isVertical, format: .bool)
            if let xIntercept = line1.xIntercept {
                LabeledContent("xIntercept", value: xIntercept, format: .point)
            }
            else {
                LabeledContent("xIntercept", value: "none")
            }
            if let yIntercept = line1.yIntercept {
                LabeledContent("yIntercept", value: yIntercept, format: .point)
            }
            else {
                LabeledContent("yIntercept", value: "none")
            }
            LabeledContent("Slope", value: line1.slope, format: .number)
        }
        Section("Line (Slope Intercept form)") {
            if let slopeInterceptForm = line1.slopeInterceptForm {
                LabeledContent("m", value: slopeInterceptForm.m, format: .number)
                LabeledContent("b", value: slopeInterceptForm.b, format: .number)
            }
            else {
                Text("VERTICAL")
            }
        }
    }
}
