import CoreGraphics

public extension Polygon {
    func toScanlines(step: CGFloat = 1.0) -> [LineSegment] {
        let bounds: CGRect = .boundingBox(points: points)
        let segments: [LineSegment] = toLineSegments()

        // swiftlint:disable:next closure_body_length
        let rays = stride(from: bounds.minY, to: bounds.maxY, by: step).flatMap { (y: CGFloat) -> [LineSegment] in
            let scanLine = LineSegment(first: CGPoint(x: bounds.minX, y: y), second: CGPoint(x: bounds.maxX, y: y))
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
                        if intersection == segment.second {
                            return []
                        }
                        else if intersection == segment.first {
                            let previousSegment = segments[(segments.count + index - 1) % segments.count]
                            if (previousSegment.first.y - y).sign == (segment.second.y - y).sign {
                                return [intersection, intersection]
                            }
                        }
                        return [intersection]
                    case .overlap:
                        return []
                    }
                }
                .sorted { $0.x < $1.x }

            let lines = intersections.pairs()
                .map { first, second -> LineSegment in
                    LineSegment(first: first, second: second ?? first)
                }
            return lines
        }

        return rays
    }
}

public func polygonToScanlines(_ polygon: Polygon, step: CGFloat = 1.0) -> [LineSegment] {
    let bounds: CGRect = .boundingBox(points: polygon.points)
    let segments: [LineSegment] = polygon.toLineSegments()

    // swiftlint:disable:next closure_body_length
    let rays = stride(from: bounds.minY, to: bounds.maxY, by: step).flatMap { (y: CGFloat) -> [LineSegment] in
        let scanLine = LineSegment(first: CGPoint(x: bounds.minX, y: y), second: CGPoint(x: bounds.maxX, y: y))
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
                    if intersection == segment.second {
                        return []
                    }
                    else if intersection == segment.first {
                        let previousSegment = segments[(segments.count + index - 1) % segments.count]
                        if (previousSegment.first.y - y).sign == (segment.second.y - y).sign {
                            return [intersection, intersection]
                        }
                    }
                    return [intersection]
                case .overlap:
                    return []
                }
            }
            .sorted { $0.x < $1.x }

        let lines = intersections.pairs()
            .map { first, second -> LineSegment in
                LineSegment(first: first, second: second ?? first)
            }
        return lines
    }

    return rays
}
