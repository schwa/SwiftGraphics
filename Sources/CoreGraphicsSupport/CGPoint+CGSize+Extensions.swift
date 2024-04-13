import CoreGraphics

public extension CGPoint {
    init(_ size: CGSize) {
        self = Self(size.width, size.height)
    }
}

public extension CGSize {
    init(_ point: CGPoint) {
        self = Self(point.x, point.y)
    }
}
