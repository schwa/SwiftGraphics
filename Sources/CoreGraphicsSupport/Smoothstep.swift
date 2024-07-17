import BaseSupport
import Foundation

// MARK: Smoothstep (https://en.wikipedia.org/wiki/Smoothstep)

public func smoothstep<T>(from edge0: T, to edge1: T, by x: T) -> T where T: FloatingPoint {
    // Scale, bias and saturate x to 0..1 range
    let x = clamp((x - edge0) / (edge1 - edge0), to: 0 ... 1)
    // Evaluate polynomial
    return x * x * (3 - 2 * x)
}

public func smootherstep<T>(from edge0: T, to edge1: T, by x: T) -> T where T: FloatingPoint {
    // Scale, and clamp x to 0..1 range
    let x = clamp((x - edge0) / (edge1 - edge0), to: 0 ... 1)
    // Evaluate polynomial
    // error: the compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions
    // x * x * x * (x * (x * 6 - 15) + 10)
    let p1 = x * x * x
    let p2 = x * 6 - 15
    let p3 = (x * p2 + 10)
    return p1 * p3
}
