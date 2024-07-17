import CoreGraphics
import simd

public func wrap(_ value: Double, to range: ClosedRange<Double>) -> Double {
    let size = range.upperBound - range.lowerBound
    let normalized = value - range.lowerBound
    return (normalized.truncatingRemainder(dividingBy: size) + size).truncatingRemainder(dividingBy: size) + range.lowerBound
}

public func wrap(_ point: CGPoint, to rect: CGRect) -> CGPoint {
    CGPoint(
        x: wrap(point.x, to: rect.minX ... rect.maxX),
        y: wrap(point.y, to: rect.minY ... rect.maxY)
    )
}

public extension FloatingPoint {
    func wrapped(to range: ClosedRange<Self>) -> Self {
        let rangeSize = range.upperBound - range.lowerBound
        let wrappedValue = (self - range.lowerBound).truncatingRemainder(dividingBy: rangeSize)
        return (wrappedValue < 0 ? wrappedValue + rangeSize : wrappedValue) + range.lowerBound
    }
}

// MARK: -

public func sign(_ v: Double) -> Double {
    if v < 0 {
        return -1
    }
    else if v == 0 {
        return 0
    }
    else {
        return 1
    }
}

// MARK: -

//public func clamp<T>(_ value: T, lower: T, upper: T) -> T where T: Comparable {
//    max(min(value, upper), lower)
//}

public func clamp<T>(_ value: T, to range: ClosedRange<T>) -> T where T: Comparable {
    min(max(value, range.lowerBound), range.upperBound)
}

public extension FloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        clamp(self, to: range)
    }
}

public extension SIMD4 where Scalar == Float {
    func clamped(to range: ClosedRange<Scalar>) -> Self {
        [x.clamped(to: range), y.clamped(to: range), z.clamped(to: range), w.clamped(to: range)]
    }
}
