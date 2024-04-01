import CoreGraphics

public extension CGVector {
    init(_ dx: CGFloat, _ dy: CGFloat) {
        self = CGVector(dx: dx, dy: dy)
    }

    init(_ size: CGSize) {
        self = CGVector(dx: size.width, dy: size.height)
    }
}
