import CoreGraphics

public protocol ConvexHullProtocol {
    static func convexHull(points: [CGPoint], presorted: Bool) -> [CGPoint]
}

public typealias ConvexHull = MonotoneChain
