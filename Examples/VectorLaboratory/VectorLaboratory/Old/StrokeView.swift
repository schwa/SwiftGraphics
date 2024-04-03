import Algorithms
import CoreGraphicsSupport
import SwiftUI
import Shapes2D

struct CustomStrokeView: View {
    let points: [CGPoint]

    var segments: [LineSegment] {
        points.windows(ofCount: 2).map(\.tuple).map {
            LineSegment($0, $1)
        }
    }

    var body: some View {
        Canvas { context, _ in
            // Fake some widths
            let widths = segments.indexed().map { index, _ in 20.0 * (CGFloat(index) + 1.5) }
            for window in AnySequence({ zip(segments, widths).peekingWindow() }) {
                let (previousSegment, currentSegment, nextSegment) = (window.previous?.0, window.current.0, window.next?.0)
                let (previousWidth, currentWidth, nextWidth) = (window.previous?.1, window.current.1, window.next?.1)
                var currentLeftSegment = currentSegment.parallel(offset: -currentWidth / 2)
                var currentRightSegment = currentSegment.parallel(offset: currentWidth / 2)
                if let previousWidth, let previousLeft = previousSegment?.parallel(offset: -previousWidth / 2.0), case .point(let point) = LineSegment.intersection(previousLeft, currentLeftSegment) {
                    context.drawDot(at: point)
                    currentLeftSegment.start = point
                }
                if let previousWidth, let previousRight = previousSegment?.parallel(offset: +previousWidth / 2.0), case .point(let point) = LineSegment.intersection(previousRight, currentRightSegment) {
                    context.drawDot(at: point)
                    currentRightSegment.start = point
                }
                if let nextWidth, let nextLeft = nextSegment?.parallel(offset: -nextWidth / 2.0), case .point(let point) = LineSegment.intersection(currentLeftSegment, nextLeft) {
                    context.drawDot(at: point)
                    currentLeftSegment.end = point
                }
                if let nextWidth, let nextRight = nextSegment?.parallel(offset: +nextWidth / 2.0), case .point(let point) = LineSegment.intersection(currentRightSegment, nextRight) {
                    context.drawDot(at: point)
                    currentRightSegment.end = point
                }
                context.stroke(Path(lineSegment: currentLeftSegment), with: .color(.red))
                context.stroke(Path(lineSegment: currentRightSegment), with: .color(.green))
            }
        }
    }
}
