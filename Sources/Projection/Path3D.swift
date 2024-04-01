import simd

public struct Path3D {
    public enum Element {
        case move(to: SIMD3<Float>)
        case addLine(to: SIMD3<Float>)
        case closePath
    }

    public var elements: [Element] = []

    public init() {
    }

    public init(builder: (inout Path3D) -> Void) {
        var path = Path3D()
        builder(&path)
        self = path
    }

    public mutating func move(to: SIMD3<Float>) {
        elements.append(.move(to: to))
    }

    public mutating func addLine(to: SIMD3<Float>) {
        elements.append(.addLine(to: to))
    }

    public mutating func closePath() {
        elements.append(.closePath)
    }
}

extension Path3D: CustomStringConvertible {
    public var description: String {
        "Path3D(elements: \(elements.map(\.description).joined(separator: ", "))"
    }
}

extension Path3D.Element: CustomStringConvertible {
    public var description: String {
        switch self {
        case .move(let point):
            ".move(to: [\(point.x), \(point.y), \(point.z)])"
        case .addLine(let point):
            ".addLine(to: [\(point.x), \(point.y), \(point.z)])"
        case .closePath:
            ".closePath"
        }
    }
}
