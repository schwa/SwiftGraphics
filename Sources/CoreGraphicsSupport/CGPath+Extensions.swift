import CoreGraphics

public extension CGPath {
    static func circle(center: CGPoint = .zero, radius: CGFloat) -> CGPath {
        let rect = CGRect(x: center.x, y: center.y, width: radius * 2, height: radius * 2)
        return CGPath(ellipseIn: rect, transform: nil)
    }

    static func line(from: CGPoint, to: CGPoint) -> CGPath {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

public extension CGPath {
    static func + (lhs: CGPath, rhs: CGPath) -> CGPath {
        let path = lhs.mutableCopy()!
        path.addPath(rhs)
        return path
    }
}
