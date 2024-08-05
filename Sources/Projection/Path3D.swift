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

    public init(builder: (inout Self) -> Void) {
        var path = Self()
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

public extension Path3D {
    mutating func addPath(_ path: Path3D) {
        elements.append(contentsOf: path.elements)
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
