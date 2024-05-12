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

        for element in elements {
            print(element(), to: &s)
        }
        print(#"</svg>"#, to: &s)
        return s
    }
}
