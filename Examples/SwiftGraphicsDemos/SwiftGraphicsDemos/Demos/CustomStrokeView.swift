import Algorithms
import CoreGraphicsSupport
import Shapes2D
import SwiftUI

// https://dl.acm.org/doi/abs/10.1145/3386569.3392392

struct CustomStrokeEditor: View {
    @State
    var points: [CGPoint] = [[50, 50], [250, 50], [300, 100]]

    var body: some View {
        ZStack {
            LegacyPathEditor(points: $points)
//            PathEditor(values: Array(points.enumerated()), id: \.0, position: \.1)
            CustomStrokeView(points: points)
                .allowsHitTesting(false)
        }
    }
}

struct CustomStrokeView: View {
    let points: [CGPoint]

    let strokeStyle = StrokeStyle(lineWidth: 120, lineCap: .butt, lineJoin: .miter, miterLimit: 199_990)

    var segments: [LineSegment] {
        points.windows(ofCount: 2).map(\.tuple).map {
            LineSegment($0, $1)
        }
    }

    var body: some View {
        Canvas { context, _ in
            context.stroke(Path(lines: points).strokedPath(strokeStyle), with: .color(.indigo.opacity(0.2)), lineWidth: 10)
            let points = [60.0, -60.0].map { offset in
                [segments.first!.parallel(offset: offset).start] + segments.windows(ofCount: 2).map { segments in
                    let segments = Array(segments)
                    let first = segments[0].parallel(offset: offset)
                    let second = segments[1].parallel(offset: offset)
                    if case .point(let point) = Line.intersection(first.line, second.line) {
                        return point
                    }
                    else {
                        fatalError()
                    }
                }
                    + [segments.last!.parallel(offset: offset).end]
            }

            for points in points {
                context.stroke(Path(lines: points), with: .color(.red), lineWidth: 5)
            }
        }
    }
}
