import Algorithms
import CoreGraphics
import Shapes2D

public extension Polygon {
    func toScanlines(step: CGFloat = 1.0) -> [LineSegment] {
        let bounds: CGRect = .boundingBox(points: vertices)
        let segments: [LineSegment] = toLineSegments()

        // swiftlint:disable:next closure_body_length
        return stride(from: bounds.minY, to: bounds.maxY, by: step).flatMap { (y: CGFloat) -> [LineSegment] in
            let scanLine = LineSegment(CGPoint(x: bounds.minX, y: y), CGPoint(x: bounds.maxX, y: y))
            let intersections = segments.enumerated()
                .flatMap { (index: Int, segment: LineSegment) -> [CGPoint] in
                    guard let intersection: LineSegmentIntersection = segment.advancedIntersection(scanLine) else {
                        return []
                    }
                    switch intersection {
                    case .intersect(let intersection):
                        return [intersection]
                    case .endIntersect(let intersection):

                        // http://www.sunshine2k.de/coding/java/Polygon/Filling/FillPolygon.htm
                        if intersection == segment.end {
                            return []
                        }
                        else if intersection == segment.start {
                            let previousSegment = segments[(segments.count + index - 1) % segments.count]
                            if (previousSegment.start.y - y).sign == (segment.end.y - y).sign {
                                return [intersection, intersection]
                            }
                        }
                        return [intersection]
                    case .overlap:
                        return []
                    }
                }
                .sorted { $0.x < $1.x }

            return intersections.pairs()
                .map { first, second -> LineSegment in
                    LineSegment(first, second ?? first)
                }
        }
    }
}

public func polygonToScanlines(_ polygon: Polygon, step: CGFloat = 1.0) -> [LineSegment] {
    let bounds: CGRect = .boundingBox(points: polygon.vertices)
    let segments: [LineSegment] = polygon.toLineSegments()

    // swiftlint:disable:next closure_body_length
    return stride(from: bounds.minY, to: bounds.maxY, by: step).flatMap { (y: CGFloat) -> [LineSegment] in
        let scanLine = LineSegment(CGPoint(x: bounds.minX, y: y), CGPoint(x: bounds.maxX, y: y))
        let intersections = segments.enumerated()
            .flatMap { (index: Int, segment: LineSegment) -> [CGPoint] in
                guard let intersection: LineSegmentIntersection = segment.advancedIntersection(scanLine) else {
                    return []
                }

                switch intersection {
                case .intersect(let intersection):
                    return [intersection]
                case .endIntersect(let intersection):

                    // http://www.sunshine2k.de/coding/java/Polygon/Filling/FillPolygon.htm
                    if intersection == segment.end {
                        return []
                    }
                    else if intersection == segment.start {
                        let previousSegment = segments[(segments.count + index - 1) % segments.count]
                        if (previousSegment.start.y - y).sign == (segment.end.y - y).sign {
                            return [intersection, intersection]
                        }
                    }
                    return [intersection]
                case .overlap:
                    return []
                }
            }
            .sorted { $0.x < $1.x }

        return intersections.pairs()
            .map { first, second -> LineSegment in
                LineSegment(first, second ?? first)
            }
    }
}

extension Collection {
    func pairs() -> [(Element, Element?)] {
        chunks(ofCount: 2).map {
            let a = Array($0)
            return (a[0], a.count == 2 ? a[1] : nil)
        }
    }
}
