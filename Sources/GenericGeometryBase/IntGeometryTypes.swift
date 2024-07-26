import CoreGraphics

extension Int: ScalarType {
}

// MARK: -

public struct IntPoint {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

extension IntPoint: Equatable {
}

extension IntPoint: Hashable {
}

extension IntPoint: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Int...) {
        assert(elements.count == 2)
        x = elements[0]
        y = elements[1]
    }
}

// MARK: -

public struct IntSize {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

extension IntSize: CustomStringConvertible {
    public var description: String {
        "(\(width), \(height))"
    }
}

extension IntSize: Equatable {
}

extension IntSize: Hashable {
}

// MARK: -

public struct IntRect {
    public var origin: IntPoint
    public var size: IntSize

    public init(origin: IntPoint, size: IntSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Int, y: Int, width: Int, height: Int) {
        origin = IntPoint(x: x, y: y)
        size = IntSize(width: width, height: height)
    }

    public init(_ x: Int, _ y: Int, _ width: Int, _ height: Int) {
        origin = IntPoint(x: x, y: y)
        size = IntSize(width: width, height: height)
    }
}

extension IntRect: Equatable {
}

extension IntRect: Hashable {
}

// MARK: -

extension IntPoint: PointType {
}

extension IntSize: SizeType {
}

extension IntRect: RectType {
    public typealias Scalar = Int
    public typealias Point = IntPoint
    public typealias Size = IntSize
}

extension IntSize: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Int...) {
        assert(elements.count == 2)
        width = elements[0]
        height = elements[1]
    }
}

public extension IntPoint {
    init(_ x: Int, _ y: Int) {
        self.init(x: x, y: y)
    }
}

public extension IntRect {
    func offset(by point: IntPoint) -> IntRect {
        IntRect(origin: origin + point, size: size)
    }

    func offset(x: Int, y: Int) -> IntRect {
        offset(by: IntPoint(x, y))
    }
}

public struct IntRectSequence: Sequence {
    private let rect: IntRect

    public init(rect: IntRect) {
        self.rect = rect
    }

    __consuming public func makeIterator() -> Iterator {
        Iterator(rect: rect)
    }

    public struct Iterator: IteratorProtocol {
        private let rect: IntRect
        private var x: Int
        private var y: Int

        init(rect: IntRect) {
            self.rect = rect

            x = rect.minX
            y = rect.minY
        }

        public mutating func next() -> IntPoint? {
            if y == rect.maxY {
                return nil
            }
            let point = IntPoint(x: x, y: y)

            x += 1
            if x == rect.maxX {
                x = rect.minX
                y += 1
            }
            return point
        }
    }
}

public extension IntRect {
    init(minX: Int, minY: Int, maxX: Int, maxY: Int) {
        self.init(origin: .init(x: minX, y: minY), size: .init(width: maxX - minX + 1, height: maxY - minY + 1))
    }

    var scalars: [Int] {
        [origin.x, origin.y, size.width, size.height]
    }
}

public extension IntPoint {
    init(_ simd: SIMD2<Float>) {
        self = IntPoint(Int(simd.x), Int(simd.y))
    }
}

public extension IntSize {
    init(_ v: SIMD2<Float>) {
        self = IntSize(Int(v.x), Int(v.y))
    }
}

public extension IntSize {
    func contains(_ point: IntPoint) -> Bool {
        point.x >= 0 && point.x < width && point.y >= 0 && point.y < height
    }
}
