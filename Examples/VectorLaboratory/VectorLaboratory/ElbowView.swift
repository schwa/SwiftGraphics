import CoreGraphicsSupport
import SwiftUI
import VectorSupport

struct ElbowView: View {
    let points: [CGPoint]
    let width: CGFloat = 20

    var body: some View {
        Canvas { context, _ in
            let angles = points.indexed().map { index, point in
                switch index {
                case points.startIndex:
                    return CGPoint.angle(point, points[index + 1])
                case points.endIndex - 1:
                    return CGPoint.angle(points[index - 1], point)
                default:
                    let angle0 = CGPoint.angle(points[index - 1], point)
                    let angle1 = CGPoint.angle(point, points[index + 1])
                    return (angle0 + angle1) / 2
                }
            }
            let lines = zip(points, angles).map { point, angle in
                let left = CGPoint(origin: point, distance: width / 2, angle: angle - .degrees(90))
                let right = CGPoint(origin: point, distance: width / 2, angle: angle + .degrees(90))
                return (left: left, right: right)
            }
            context.stroke(Path(lineSegments: points), with: .color(.black.opacity(0.5)))
            context.stroke(Path(lineSegments: lines.map(\.left)), with: .color(.red))
            context.stroke(Path(lineSegments: lines.map(\.right)), with: .color(.green))

            do {
                let segments = points.windows(ofCount: 2).map(\.tuple)
                let lengths = segments.map(CGPoint.distance)
                let totalLength = segments.reduce(0) { $0 + CGPoint.distance($1) }

                var result: [[CGFloat]] = [[]]
                var iterator = lengths.makeIterator()
                var lastCumulativeLength: CGFloat = 0
                var currentLength: CGFloat = iterator.next()!
                var cumulativeLength = currentLength
                for d in stride(from: 0, through: totalLength, by: 20) {
                    if d > cumulativeLength {
                        lastCumulativeLength = cumulativeLength
                        currentLength = iterator.next()!
                        cumulativeLength += currentLength
                        result += [[]]
                    }
                    var last = result.popLast()!
                    last.append((d - lastCumulativeLength) / currentLength)
                    result.append(last)
                }

                for (lengths, lines) in zip(result, lines.windows(ofCount: 2).map(\.tuple)) {
                    let left = (lines.0.left, lines.1.left)
                    let right = (lines.0.right, lines.1.right)

                    for length in lengths {
                        let left = lerp(from: left.0, to: left.1, by: length)
                        let right = lerp(from: right.0, to: right.1, by: length)
                        context.stroke(Path(lineSegment: (left, right)), with: .color(.purple))
                    }
                }
            }
        }
    }
}
