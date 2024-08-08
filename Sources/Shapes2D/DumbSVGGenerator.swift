import CoreGraphics

public struct DumbSVGGenerator {
    var elements: [() -> String] = []

    //      <rect x="10" y="10" width="30" height="30" stroke="black" fill="transparent" stroke-width="5"/>

    public mutating func add(_ value: LineSegment, color: String = "black", arrow: Bool = false) {
        elements.append {
            "<line x1=\"\(value.start.x)\" y1=\"\(value.start.y)\" x2=\"\(value.end.x)\" y2=\"\(value.end.y)\" fill=\"none\" stroke=\"\(color)\" \(arrow ? "marker-end=\"url(#head)\"" : "")/>"
        }
    }

    public mutating func add(_ value: CGRect, stroke: String = "black", fill: String = "none") {
        elements.append {
            "<rect x=\"\(value.minX)\" y=\"\(value.minY)\" width=\"\(value.width)\" height=\"\(value.height)\" fill=\"\(fill)\" stroke=\"\(stroke)\"/>"
        }
    }
}
