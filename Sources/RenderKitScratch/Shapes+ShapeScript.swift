import Shapes3D

public protocol ShapeScriptEncodable {
    func encodeToShapeScript() throws -> String
}

// https://shapescript.info/mac/
extension Sphere3D: ShapeScriptEncodable {
    public func encodeToShapeScript() throws -> String {
        """
        sphere {
            size \(radius * 2)
            position \(center.x) \(center.y) \(center.z)
            detail 36
        }
        """
    }
}

extension LineSegment3D: ShapeScriptEncodable {
    public func encodeToShapeScript() throws -> String {
        """
        path {
            point \(start.x) \(start.y) \(start.z)
            point \(end.x) \(end.y) \(end.z)
        }
        """
    }
}

extension Line3D: ShapeScriptEncodable {
    public func encodeToShapeScript() throws -> String {
        let segment = LineSegment3D(start: point + -direction * 1_000, end: point + direction * 1_000)
        return try segment.encodeToShapeScript()
    }
}
