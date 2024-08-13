import Algorithms
import BaseSupport
import CoreGraphicsSupport
import Shapes2D
import SwiftUI

// https://dl.acm.org/doi/abs/10.1145/3386569.3392392

struct CustomStrokeEditorDemoView: View, DemoView {
    @State
    private var points: [CGPoint] = [[50, 50], [250, 50], [300, 100]]

    var body: some View {
        ZStack {
            LegacyPathEditor(points: $points)
            CustomStrokeView(points: points)
                .allowsHitTesting(false)
        }
    }
}

struct CustomStrokeView: View {
    let points: [CGPoint]

    @State
    var thickness = 120.0

    let strokeStyle = StrokeStyle(lineWidth: 120, lineCap: .butt, lineJoin: .miter, miterLimit: 199_990)

    var segments: [LineSegment] {
        points.windows(ofCount: 2).map(\.tuple2).map {
            LineSegment($0, $1)
        }
    }

    var body: some View {
        Canvas { context, _ in
            context.stroke(Path(lines: points), with: .color(.indigo.opacity(0.05)), lineWidth: 120)

            context.stroke(Path(lines: points).strokedPath(strokeStyle), with: .color(.indigo.opacity(0.2)), lineWidth: 10)
            let points = [thickness * 0.5, thickness * -0.5].map { offset in
                [segments.first!.parallel(offset: offset).start] + segments.windows(ofCount: 2).map { segments in
                    let segments = Array(segments)
                    let first = segments[0].parallel(offset: offset)
                    let second = segments[1].parallel(offset: offset)
                    if case .point(let point) = Line.intersection(first.line, second.line) {
                        return point
                    } else {
                        unreachable()
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
