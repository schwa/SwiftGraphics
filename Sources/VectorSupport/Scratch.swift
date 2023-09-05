import Foundation
import SwiftUI
import CoreGraphicsSupport

internal extension ComparisonResult {
    static func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        else if lhs < rhs {
            return .orderedAscending
        }
        else {
            return .orderedDescending
        }
    }
}

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
        return Path(ellipseIn: CGRect(center: center, radius: radius))
    }
    
    init(lineSegment: LineSegment) {
        self = Path { path in
            path.move(to: lineSegment.start)
            path.addLine(to: lineSegment.end)
        }
    }
}

public struct DumbSVGGenerator {
    
    var elements: [() -> String] = []
    
    //      <rect x="10" y="10" width="30" height="30" stroke="black" fill="transparent" stroke-width="5"/>
    
    public mutating func add(_ value: LineSegment, color: String = "black", arrow: Bool = false) {
        elements.append {
            return "<line x1=\"\(value.start.x)\" y1=\"\(value.start.y)\" x2=\"\(value.end.x)\" y2=\"\(value.end.y)\" fill=\"none\" stroke=\"\(color)\" \(arrow ? "marker-end=\"url(#head)\"" : "")/>"
        }
    }
    
    public mutating func add(_ value: CGRect, stroke: String = "black", fill: String = "none") {
        elements.append {
            return "<rect x=\"\(value.minX)\" y=\"\(value.minY)\" width=\"\(value.width)\" height=\"\(value.height)\" fill=\"\(fill)\" stroke=\"\(stroke)\"/>"
        }
    }
}

extension DumbSVGGenerator: CustomStringConvertible {
    public var description: String {
        var s = ""
        print(#"<?xml version="1.0" standalone="no"?>"#, to: &s)
        print(#"<svg version="1.1" xmlns="http://www.w3.org/2000/svg">"#, to: &s)
        print(#"""
        <defs>
        <marker id="head" orient="auto" markerWidth="3" markerHeight="4" refX="0.1" refY="2">
        <path d="M0,0 V4 L2,2 Z"/>
        </marker>
        </defs>
        """#, to: &s)

//        <path
//          id='arrow-line'
//          marker-end='url(#head)'
//          stroke-width='4'
//          fill='none' stroke='black'
//          d='M0,0, 80 100,120'
//          />


        elements.forEach { element in
            print(element(), to: &s)
        }
        print(#"</svg>"#, to: &s)
        return s
    }
}

