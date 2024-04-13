import CoreGraphicsSupport
import SwiftUI

// import Algorithms
// import Observation
import Shapes2D

typealias LineSegment = Shapes2D.LineSegment

public struct Sketch {
    public var elements: [Element]

    public init() {
        elements = []
    }
}

// MARK: -

public struct Element: Identifiable {
    public let id: UUID
    public var color: Color
    public var label: String
    public var shape: SketchShapeEnum

    public init(color: Color = .black, label: String = "", shape: SketchShapeEnum) {
        id = UUID()
        self.color = color
        self.label = label
        self.shape = shape
    }
}

// MARK: -

public protocol PathProducing {
    var path: Path { get }
}

public protocol SketchShape: PathProducing, Equatable, Codable {
    associatedtype Handles: HandlesProtocol
    var handles: Self.Handles { get set }
}

// MARK: -

public protocol HandlesProtocol {
    associatedtype Key: Hashable
    var positions: [Key: CGPoint] { get set }
}

public struct SingleHandle: HandlesProtocol {
    public var position: CGPoint

    public var positions: [AnyHashable: CGPoint] {
        get {
            ["_": position]
        }
        set {
            position = newValue["_"]!
        }
    }
}

// MARK: -

public enum SketchShapeEnum: Equatable, Codable {
    case point(Sketch.Point)
    case lineSegment(Sketch.LineSegment)
    case rectangle(Sketch.Rectangle)
}

public extension SketchShapeEnum {
    init(_ shape: some SketchShape) {
        switch shape {
        case let shape as Sketch.Point:
            self = .point(shape)
        case let shape as Sketch.LineSegment:
            self = .lineSegment(shape)
        case let shape as Sketch.Rectangle:
            self = .rectangle(shape)
        default:
            fatalError()
        }
    }

    var shape: any SketchShape {
        switch self {
        case .point(let shape):
            shape
        case .lineSegment(let shape):
            shape
        case .rectangle(let shape):
            shape
        }
    }

    func `as`<Shape>(_ type: Shape.Type) -> Shape? where Shape: SketchShape {
        shape as? Shape
    }
}

public extension Sketch {
    struct Point: SketchShape {
        public var position: CGPoint

        public init(position: CGPoint) {
            self.position = position
        }

        public var handles: SingleHandle {
            get {
                SingleHandle(position: position)
            }
            set {
                position = newValue.position
            }
        }

        public var path: Path {
            Path.circle(center: position, radius: 4)
        }
    }

    struct LineSegment: SketchShape {
        public var start: CGPoint
        public var end: CGPoint

        public init(start: CGPoint, end: CGPoint) {
            self.start = start
            self.end = end
        }

        public var path: Path {
            Path.line(from: start, to: end)
        }

        public struct Handle: HandlesProtocol {
            var start: CGPoint
            var end: CGPoint

            public var positions: [WritableKeyPath<Handle, CGPoint>: CGPoint] {
                get {
                    [\Handle.start: start, \Handle.end: end]
                }
                set {
                    start = newValue[\Handle.start]!
                    end = newValue[\Handle.end]!
                }
            }
        }

        public var handles: Handle {
            get {
                Handle(start: start, end: end)
            }
            set {
                (start, end) = (newValue.start, newValue.end)
            }
        }
    }

    struct Rectangle: SketchShape {
        public var start: CGPoint
        public var end: CGPoint

        public init(start: CGPoint, end: CGPoint) {
            self.start = start
            self.end = end
        }

        public var path: Path {
            Path(CGRect(points: (start, end)))
        }

        public struct Handle: HandlesProtocol {
            var start: CGPoint
            var end: CGPoint

            public var positions: [WritableKeyPath<Handle, CGPoint>: CGPoint] {
                get {
                    [\Handle.start: start, \Handle.end: end]
                }
                set {
                    start = newValue[\Handle.start]!
                    end = newValue[\Handle.end]!
                }
            }
        }

        public var handles: Handle {
            get {
                Handle(start: start, end: end)
            }
            set {
                (start, end) = (newValue.start, newValue.end)
            }
        }
    }
}

public extension CGRect {
    init(_ rectangle: Sketch.Rectangle) {
        self = CGRect(points: (rectangle.start, rectangle.end))
    }
}

public extension LineSegment {
    init(_ shape: Sketch.LineSegment) {
        self = LineSegment(shape.start, shape.end)
    }
}
