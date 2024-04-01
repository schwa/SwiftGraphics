import CoreGraphics
import simd

public extension CGPoint {
    /**
     ```swift doctest
     CGPoint(SIMD2<Float>(1, 2)) // => CGPoint(x: 1, y: 2)
     ```
     */
    init(_ vector: SIMD2<some BinaryFloatingPoint>) {
        self = CGPoint(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
}

public extension CGSize {
    /**
     ```swift doctest
     CGSize(SIMD2<Float>(1, 2)) // => CGSize(width: 1, height: 2)
     ```
     */
    init(_ vector: SIMD2<some BinaryFloatingPoint>) {
        self.init(width: CGFloat(vector.x), height: CGFloat(vector.y))
    }
}

public extension SIMD2 where Scalar: BinaryFloatingPoint {
    /**
     ```swift doctest
     SIMD2<Float>(CGPoint(x: 1, y: 2)) // => SIMD2<Float>(1, 2)
     ```
     */
    init(_ point: CGPoint) {
        self = SIMD2<Scalar>(Scalar(point.x), Scalar(point.y))
    }

    /**
     ```swift doctest
     SIMD2<Float>(CGSize(width: 1, height: 2)) // => SIMD2<Float>(1, 2)
     ```
     */
    init(_ size: CGSize) {
        self = SIMD2<Scalar>(Scalar(size.width), Scalar(size.height))
    }
}
