import SwiftUI
import CoreGraphicsSupport
import Algorithms

struct OldContentView: View {

    @State
    var points: [CGPoint] = [[50, 50], [250, 50], [300, 100]]
    
    var body: some View {
        ZStack {
            PathCanvas(points: $points)
            CustomStrokeView(points: points)
            .contentShape(.interaction, EmptyShape())
                
        }
    }
    
}

struct CustomStrokeView: View {
    let points: [CGPoint]
    
    var segments: [LineSegment] {
        points.windows(ofCount: 2).map(\.tuple).map {
            LineSegment(start: $0, end: $1)
        }
    }
    
    @State
    var widths: [CGFloat] = []
    
    var body: some View {
        Canvas { context, size in

            for segment in segments {
                //context.stroke(Path(segment), with: .color(.red))
                let left = segment.parallel(offset: -10)
                context.stroke(Path(left), with: .color(.red))
                let right = segment.parallel(offset: 10)
                context.stroke(Path(right), with: .color(.green))
            }
            
            
        }
        .onAppear {
            self.widths = Array(repeating: 10, count: segments.count)
        }
        .onChange(of: points) {
            self.widths = Array(repeating: 10, count: segments.count)
        }
    }
}

enum Line: Equatable {
    case vertical(x: Double)
    case slopeIntercept(m: Double, b: Double) // y = mx+b
}

extension Line {
    init(points: (CGPoint, CGPoint)) {
        let x1 = points.0.x
        let y1 = points.0.y
        let x2 = points.1.x
        let y2 = points.1.y
        if x1 == x2 {
            self = .vertical(x: x1)
        }
        else {
            let m = (y2 - y1) / (x2 - x1)
            let b = y1 - m * x1
            self = .slopeIntercept(m: m, b: b)
        }
    }
}

enum Intersection {
    case none
    case point(CGPoint)
    case everywhere
}

func intersection(_ lhs: Line, _ rhs: Line) -> Intersection {
    if lhs == rhs {
        return .everywhere
    }
    switch (lhs, rhs) {
    case (.vertical, .vertical):
        return .everywhere
    case (.vertical, .slopeIntercept(_, let b)):
        return .point(CGPoint(0, b))
    case (.slopeIntercept(_, let b), .vertical):
        return .point(CGPoint(0, b))
    case (.slopeIntercept(let m1, let b1), .slopeIntercept(let m2, let b2)):
        if m1 == m2 {
            return .none
        }
        let x = (b2 - b1) / (m1 - m2)
        let y = m1 * x + b1
        return .point(CGPoint(x, y))
    }
}


extension LineSegment {
    
    func map(_ t: (CGPoint) throws -> CGPoint) rethrows -> LineSegment {
        return LineSegment(start: try t(start), end: try t(end))
    }
    
    func parallel(offset: CGFloat) -> LineSegment {
        let angle = angle(start, end) - .degrees(90)
        let offset = CGPoint(distance: offset, angle: angle)
        return map { $0 + offset }
    }
    
}

struct ElbowView: View {
    let points: [CGPoint]
    let width: CGFloat = 20
    
    var body: some View {
        Canvas { context, size in
            let angles = points.indexed().map { index, point in
                switch index {
                case points.startIndex:
                    return angle(point, points[index+1])
                case points.endIndex - 1:
                    return angle(points[index-1], point)
                default:
                    let angle0 = angle(points[index-1], point)
                    let angle1 = angle(point, points[index+1])
                    return (angle0 + angle1) / 2
                }
            }
            let lines = zip(points, angles).map { point, angle in
                let left = CGPoint(origin: point, distance: width / 2, angle: angle - .degrees(90))
                let right = CGPoint(origin: point, distance: width / 2, angle: angle + .degrees(90))
                return (left: left, right: right)
            }
            context.stroke(Path(lines: points), with: .color(.black.opacity(0.5)))
            context.stroke(Path(lines: lines.map(\.left)), with: .color(.red))
            context.stroke(Path(lines: lines.map(\.right)), with: .color(.green))

            do {
                let segments = points.windows(ofCount: 2).map(\.tuple)
                let lengths = segments.map(distance)
                let totalLength = segments.reduce(0) { return $0 + distance($1) }

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
                        context.stroke(Path(line: (left, right)), with: .color(.purple))

                        
                    }
                }
            }

        }
    }
}

struct StairView: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(x: 10, y: 10, width: 500, height: 100)
            context.stroke(Path(rect), with: .color(.red.opacity(0.5)))
            let points = [rect.minXMinY, rect.maxXMinY, rect.maxXMaxY, rect.minXMaxY]
            let d0 = distance(points[0], points[1])
            let d1 = distance(points[1], points[2])
            let longAxisPoints = d0 > d1 ? ((points[0], points[1]), (points[3], points[2])) : ((points[0], points[3]), (points[1], points[2]))
            let d = max(d0, d1)
            for n in stride(from: 0, through: d, by: 20) {
                let a = (longAxisPoints.0.1 - longAxisPoints.0.0) * (n / d) + longAxisPoints.0.0
                context.fill(Path(ellipseIn: CGRect(center: a, radius: 2)), with: .color(.red))
                let b = (longAxisPoints.1.1 - longAxisPoints.1.0) * (n / d) + longAxisPoints.1.0
                context.fill(Path(ellipseIn: CGRect(center: b, radius: 2)), with: .color(.red))
                context.stroke(Path(line: (a, b)), with: .color(.black))
            }
        }
    }
}

struct EmptyShape: Shape {
    func path(in rect: CGRect) -> Path {
        return Path()
    }
}
