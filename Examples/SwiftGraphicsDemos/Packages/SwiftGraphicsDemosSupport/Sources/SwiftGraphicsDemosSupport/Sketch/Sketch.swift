import CoreGraphicsSupport
import SwiftUI

// import Algorithms
// import Observation
import Shapes2D

typealias LineSegment = Shapes2D.LineSegment

struct Sketch {
    var elements: [Element]

    init() {
        elements = []
    }
}

// MARK: -

struct Element: Identifiable {
    let id: UUID
    var color: Color
    var label: String
    var shape: SketchShapeEnum

    init(color: Color = .black, label: String = "", shape: SketchShapeEnum) {
        id = UUID()
        self.color = color
        self.label = label
        self.shape = shape
    }
}

// MARK: -

protocol PathProducing {
    var path: Path { get }
}

protocol SketchShape: PathProducing, Equatable, Codable {
    associatedtype Handles: HandlesProtocol
    var handles: Self.Handles { get set }
}

// MARK: -

protocol HandlesProtocol {
    associatedtype Key: Hashable
    var positions: [Key: CGPoint] { get set }
}

struct SingleHandle: HandlesProtocol {
    var position: CGPoint

    var positions: [AnyHashable: CGPoint] {
        get {
            ["_": position]
        }
        set {
            position = newValue["_"]!
        }
    }
}

// MARK: -

enum SketchShapeEnum: Equatable, Codable {
    case point(Sketch.Point)
    case lineSegment(Sketch.LineSegment)
    case rectangle(Sketch.Rectangle)
}

extension SketchShapeEnum {
    init(_ shape: some SketchShape) {
        switch shape {
        case let shape as Sketch.Point:
            self = .point(shape)
        case let shape as Sketch.LineSegment:
            self = .lineSegment(shape)
        case let shape as Sketch.Rectangle:
            self = .rectangle(shape)
        default:
            fatalError("Unknown shape")
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

extension Sketch {
    struct Point: SketchShape {
        var position: CGPoint

        init(position: CGPoint) {
            self.position = position
        }

        var handles: SingleHandle {
            get {
                SingleHandle(position: position)
            }
            set {
                position = newValue.position
            }
        }

        var path: Path {
            Path.circle(center: position, radius: 4)
        }
    }

    struct LineSegment: SketchShape {
        var start: CGPoint
        var end: CGPoint

        init(start: CGPoint, end: CGPoint) {
            self.start = start
            self.end = end
        }

        var path: Path {
            Path.line(from: start, to: end)
        }

        struct Handle: HandlesProtocol {
            var start: CGPoint
            var end: CGPoint

            var positions: [WritableKeyPath<Self, CGPoint>: CGPoint] {
                get {
                    [\Self.start: start, \Self.end: end]
                }
                set {
                    start = newValue[\Self.start]!
                    end = newValue[\Self.end]!
                }
            }
        }

        var handles: Handle {
            get {
                Handle(start: start, end: end)
            }
            set {
                (start, end) = (newValue.start, newValue.end)
            }
        }
    }

    struct Rectangle: SketchShape {
        var start: CGPoint
        var end: CGPoint

        init(start: CGPoint, end: CGPoint) {
            self.start = start
            self.end = end
        }

        var path: Path {
            Path(CGRect(points: (start, end)))
        }

        struct Handle: HandlesProtocol {
            var start: CGPoint
            var end: CGPoint

            var positions: [WritableKeyPath<Self, CGPoint>: CGPoint] {
                get {
                    [\Self.start: start, \Self.end: end]
                }
                set {
                    start = newValue[\Self.start]!
                    end = newValue[\Self.end]!
                }
            }
        }

        var handles: Handle {
            get {
                Handle(start: start, end: end)
            }
            set {
                (start, end) = (newValue.start, newValue.end)
            }
        }
    }
}

extension CGRect {
    init(_ rectangle: Sketch.Rectangle) {
        self = CGRect(points: (rectangle.start, rectangle.end))
    }
}

extension LineSegment {
    init(_ shape: Sketch.LineSegment) {
        self = LineSegment(shape.start, shape.end)
    }
}
