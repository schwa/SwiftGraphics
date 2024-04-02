import Sketches
import SwiftUI
import Shapes2D

struct LineExperimentView: View {
    @Binding
    var sketch: Sketch

    var body: some View {
        Canvas { context, _ in
            for bounds in rectangles {
                for segment in lineSegments {
                    let line = segment.line
                    if let segment = line.lineSegment(bounds: bounds) {
                        context.stroke(Path(lineSegment: segment), with: .color(.red), lineWidth: 2)
                    }
                }
            }
        }
    }

    var rectangles: [CGRect] {
        sketch.elements.map(\.shape).compactMap { shape in
            shape.as(Sketch.Rectangle.self).map { CGRect($0) }
        }
    }

    var lineSegments: [LineSegment] {
        sketch.elements.map(\.shape).compactMap { shape in
            shape.as(Sketch.LineSegment.self).map { LineSegment($0) }
        }
    }
}
