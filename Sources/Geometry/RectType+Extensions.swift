// swiftlint:disable file_length

import CoreGraphics

// MARK: -

public extension RectType {
    var x: Point.Scalar {
        get {
            origin.x
        }
        set {
            origin.x = newValue
        }
    }

    var y: Point.Scalar {
        get {
            origin.y
        }
        set {
            origin.y = newValue
        }
    }

    var width: Size.Scalar {
        get {
            size.width
        }
        set {
            size.width = newValue
        }
    }

    var height: Size.Scalar {
        get {
            size.height
        }
        set {
            size.height = newValue
        }
    }
}

public extension RectType where Scalar == Point.Scalar, Scalar == Size.Scalar {
    init(size: Size) {
        self.init(origin: Point.zero, size: size)
    }

    init(x: Scalar, y: Scalar, width: Scalar, height: Scalar) {
        self.init(origin: Point(x: x, y: y), size: Size(width: width, height: height))
    }

    init(width: Scalar, height: Scalar) {
        self.init(origin: Point.zero, size: Size(width: width, height: height))
    }
}

public extension RectType where Scalar: FloatingPoint, Scalar == Point.Scalar, Scalar == Size.Scalar {
    init(center: Point, size: Size) {
        self.init(origin: center - size * Scalar(0.5), size: size)
    }

    init(center: Point, diameter: Scalar) {
        let size = Size(width: diameter, height: diameter)
        self.init(origin: center - size * Scalar(0.5), size: size)
    }

    init(center: Point, radius: Scalar) {
        let size = Size(width: radius * Scalar(2), height: radius * Scalar(2))
        self.init(origin: center - size * Scalar(0.5), size: size)
    }
}

// MARK: -

public extension RectType {
    static var zero: Self {
        self.init(origin: Point.zero, size: Size.zero)
    }

    var isEmpty: Bool {
        size.width == 0 || size.height == 0
    }
}

// MARK: -

public extension RectType where Point.Scalar: FloatingPoint {
    static var null: Self {
        self.init(origin: Point(x: Point.Scalar.infinity, y: Point.Scalar.infinity), size: Size.zero)
    }

    var isNull: Bool {
        origin == Point(x: Point.Scalar.infinity, y: Point.Scalar.infinity)
    }
}

// MARK: -

public extension RectType where Scalar == Point.Scalar, Scalar == Size.Scalar {
    /// Test: RectType_Tests.testMinMax
    var minX: Scalar {
        get {
            x
        }
        set {
            width += x - newValue
            x = newValue
        }
    }

    /// Test: RectType_Tests.testMinMax
    var minY: Scalar {
        get {
            y
        }
        set {
            height += y - newValue
            y = newValue
        }
    }

    /// Test: RectType_Tests.testMinMax
    var maxX: Scalar {
        get {
            x + width
        }
        set {
            width = newValue - x
        }
    }

    /// Test: RectType_Tests.testMinMax
    var maxY: Scalar {
        get {
            y + height
        }
        set {
            height = newValue - y
        }
    }

    var midX: Scalar {
        x + width / 2
    }

    var midY: Scalar {
        y + height / 2
    }

    // MARK: -

    var mid: Point {
        Point(x: midX, y: midY)
    }

    var minXMinY: Point {
        Point(x: minX, y: minY)
    }

    var minXMidY: Point {
        Point(x: minX, y: midY)
    }

    var minXMaxY: Point {
        Point(x: minX, y: maxY)
    }

    var midXMinY: Point {
        Point(x: midX, y: minY)
    }

    var midXMidY: Point {
        Point(x: midX, y: midY)
    }

    var midXMaxY: Point {
        Point(x: midX, y: maxY)
    }

    var maxXMinY: Point {
        Point(x: maxX, y: minY)
    }

    var maxXMidY: Point {
        Point(x: maxX, y: midY)
    }

    var maxXMaxY: Point {
        Point(x: maxX, y: maxY)
    }

    // TODO: This doens't work for int rects???
    init(minX: Scalar, minY: Scalar, maxX: Scalar, maxY: Scalar) {
        self.init(origin: Point(x: minX, y: minY), size: Size(width: maxX - minX, height: maxY - minY))
    }

    init(horizontal: Range<Scalar>, vertical: Range<Scalar>) {
        self.init(minX: horizontal.lowerBound, minY: vertical.lowerBound, maxX: horizontal.upperBound, maxY: vertical.upperBound)
    }
}

// MARK: -

public extension RectType where Scalar == Point.Scalar, Scalar == Size.Scalar {
    init(points: (Point, Point)) {
        let minX = min(points.0.x, points.1.x)
        let minY = min(points.0.y, points.1.y)
        let maxX = max(points.0.x, points.1.x)
        let maxY = max(points.0.y, points.1.y)
        self.init(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }

    mutating func normalize() {
        guard width >= 0 && height >= 0 else {
            return
        }

        if width < 0 {
            x += width
            width *= -1
        }

        if height < 0 {
            y += height
            height *= -1
        }
    }

    func normalized() -> Self {
        guard width >= 0 && height >= 0 else {
            return self
        }

        var rect = self
        rect.normalize()
        return rect
    }
}

// MARK: -

// public extension RectType where Scalar == Point.Scalar, Scalar == Size.Scalar, Point.Scalar: FloatingPoint {
//    var midX: Point.Scalar {
//        return x + width * Point.Scalar(0.5)
//    }
//
//    var midY: Point.Scalar {
//        return y + height * Point.Scalar(0.5)
//    }
//
//    var mid: Point {
//        return Point(x: midX, y: midY)
//    }
//
//    // MARK: -
//
//    var minXMinY: Point {
//        return Point(x: minX, y: minY)
//    }
//
//    var midXMinY: Point {
//        return Point(x: midX, y: minY)
//    }
//
//    var maxXMinY: Point {
//        return Point(x: maxX, y: minY)
//    }
//
//    var minXMidY: Point {
//        return Point(x: minX, y: midY)
//    }
//
//    var midXMidY: Point {
//        return Point(x: midX, y: midY)
//    }
//
//    var maxXMidY: Point {
//        return Point(x: maxX, y: midY)
//    }
//
//    var minXMaxY: Point {
//        return Point(x: minX, y: maxY)
//    }
//
//    var midXMaxY: Point {
//        return Point(x: midX, y: maxY)
//    }
//
//    var maxXMaxY: Point {
//        return Point(x: maxX, y: maxY)
//    }
// }

// MARK: -

public extension RectType where Scalar == Point.Scalar, Scalar == Size.Scalar {
    func union(_ point: Point) -> Self {
        let minX = min(minX, point.x)
        let minY = min(minY, point.y)
        let maxX = max(maxX, point.x)
        let maxY = max(maxY, point.y)
        return Self(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }

    func union(_ rect: Self) -> Self {
        let minX = min(minX, rect.minX)
        let minY = min(minY, rect.minY)
        let maxX = max(maxX, rect.maxX)
        let maxY = max(maxY, rect.maxY)
        return Self(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }

    func inset(dx: Point.Scalar, dy: Point.Scalar) -> Self {
        Self(minX: minX + dx, minY: minY + dy, maxX: maxX - dx, maxY: maxY - dy)
    }

    mutating func insetInPlace(dx: Point.Scalar, dy: Point.Scalar) {
        self = Self(minX: minX + dx, minY: minY + dy, maxX: maxX - dx, maxY: maxY - dy)
    }
}

// MARK: -

public extension RectType where Scalar == Point.Scalar, Scalar == Size.Scalar, Scalar: FloatingPoint {
    func union(_ point: Point) -> Self {
        if isNull {
            return Self(origin: point, size: Size.zero)
        }
        else {
            let minX = min(minX, point.x)
            let minY = min(minY, point.y)
            let maxX = max(maxX, point.x)
            let maxY = max(maxY, point.y)
            return Self(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
        }
    }

    func union(_ rect: Self) -> Self {
        if isNull {
            return rect
        }
        else {
            let minX = min(minX, rect.minX)
            let minY = min(minY, rect.minY)
            let maxX = max(maxX, rect.maxX)
            let maxY = max(maxY, rect.maxY)
            return Self(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
        }
    }
}

// MARK: -

public extension RectType where Scalar == Point.Scalar, Scalar == Size.Scalar {
    func contains(_ point: Point) -> Bool {
        let xInterval = minX ..< maxX
        let yInterval = minY ..< maxY
        return xInterval.contains(point.x) && yInterval.contains(point.y)
    }
}

// MARK: -

// TODO: Stop from being CG

public extension CGRect {
    func offsetBy(delta: CGPoint) -> CGRect {
        offsetBy(dx: delta.x, dy: delta.y)
    }

    var isFinite: Bool {
        isNull == false && isInfinite == false
    }

    static func unionOf(rects: [CGRect]) -> CGRect {
        rects[1 ..< rects.count].reduce(rects[0]) { accumulator, current in
            accumulator.union(current)
        }
    }

    static func unionOf(points: [CGPoint]) -> CGRect {
        points.reduce(CGRect(origin: points[0], size: CGSize.zero)) { accumulator, current in
            accumulator.union(current)
        }
    }

    func rectByUnion(point: CGPoint) -> CGRect {
        union(CGRect(center: point, radius: 0.0))
    }

//    mutating func union(point: CGPoint) {
//        unionInPlace(CGRect(center: point, radius: 0.0))
//    }

    func toTuple() -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        (origin.x, origin.y, size.width, size.height)
    }

    func partiallyIntersects(_ other: CGRect) -> Bool {
        if intersects(other) == true {
            let union = union(other)
            if self != union {
                return true
            }
        }
        return false
    }
}

public extension RectType {
    static func boundingBox<Point, Rect: RectType>(points: [Point]) -> Rect where Rect.Scalar: FloatingPoint, Rect.Scalar == Rect.Point.Scalar, Rect.Scalar == Rect.Size.Scalar, Point == Rect.Point {
        points.reduce(Rect.null) { (accumulator: Rect, element: Point) in
            accumulator.union(element)
        }
    }
}

public extension RectType where Scalar == Int, Scalar == Point.Scalar, Scalar == Size.Scalar {
    init(center: Point, size: Size) {
        precondition(size.width & 1 == 0)
        precondition(size.height & 1 == 0)
        let origin = Point(x: center.x - (size.width - 1) / 2, y: center.y - (size.height - 1) / 2)
        self.init(origin: origin, size: size)
    }

    func contains(point: Point) -> Bool {
        if point.x < minX || point.x >= maxX || point.y < minY || point.y >= maxY {
            false
        }
        else {
            true
        }
    }

    func points() -> AnySequence<Point> {
        let seq = sequence(first: Point(x: minX, y: minY)) { current in
            if self.size.width == 0 || self.size.height == 0 {
                return nil
            }
            var current = current
            current.x += 1
            if current.x >= self.maxX {
                current.x = self.minX
                current.y += 1
            }
            if current.y >= self.maxY {
                return nil
            }
            return current
        }
        return AnySequence(seq)
    }

    func intersection(_ other: IntRect) -> IntRect {
        if isEmpty || other.isEmpty {
            return IntRect.zero
        }

        let x1 = max(minX, other.minX)
        let x2 = min(maxX, other.maxX)
        let y1 = max(minY, other.minY)
        let y2 = min(maxY, other.maxY)
        // If width or height is 0, the intersection was empty.
        return IntRect(x: x1, y: y1, width: max(0, x2 - x1), height: max(0, y2 - y1))
    }
}
