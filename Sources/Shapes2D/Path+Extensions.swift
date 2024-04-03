import CoreGraphicsSupport
import Foundation
import SwiftUI

public extension Path {
    // TODO: rename "open polygonal chain" um yeah
    init(lineSegments: [CGPoint]) {
        self = Path { path in
            path.addLines(lineSegments)
        }
    }

    init(lineSegment: (CGPoint, CGPoint)) {
        self = Path { path in
            path.move(to: lineSegment.0)
            path.addLine(to: lineSegment.1)
        }
    }

    init(lineSegment: (CGPoint, CGPoint), width: CGFloat, lineCap: CGLineCap) {
        self = Path { path in
            let radius = width / 2
            let angle = CGPoint.angle(lineSegment.0, lineSegment.1)
            //            path.move(to: line.0 + CGPoint(distance: radius, angle: angle - .degrees(90)))
            path.addRelativeArc(center: lineSegment.0, radius: radius, startAngle: angle + .degrees(90), delta: .degrees(180))
            path.addLine(to: lineSegment.1 + CGPoint(distance: radius, angle: angle - .degrees(90)))
            path.addRelativeArc(center: lineSegment.1, radius: radius, startAngle: angle - .degrees(90), delta: .degrees(180))
            path.addLine(to: lineSegment.0 + CGPoint(distance: radius, angle: angle + .degrees(90)))
            path.closeSubpath()
        }
    }

    static func circle(center: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(center: center, radius: radius))
    }

    init(lineSegment: LineSegment) {
        self = Path { path in
            path.move(to: lineSegment.start)
            path.addLine(to: lineSegment.end)
        }
    }
}

