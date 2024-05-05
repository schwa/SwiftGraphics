import Foundation

// 6.2 Common Functions

// Returns fmin (fmax(x, minval), maxval).
// Results are undefined if minval › maxval.
public func clamp <T>(_ x: T, _ minval: T, _ maxval: T) -> T where T: FloatingPoint {
    min(max(x, minval), maxval)
}

//Returns the linear blend of x and y implemented as:
//x + ( у — x) * а
//a needs to be a value in the range 0.0 to 1.0. If a is not in the range 0.0 to 1.0, the return values are undefined.
public func mix <T>(_ x: T, _ y : T, _ a: T) -> T where T: FloatingPoint {
    x + (y - x) * a
}

// Clamp the specified value within the range of 0.0 to 1.0.
public func saturate <T>(x: T) -> T where T: FloatingPoint {
    clamp(x, 0, 1)
}

// Returns 1.0 if x > 0, -0.0 if x = -0.0, +0.0 if x = +0.0, or -1.0 if x < 0. Returns 0.0 if x is a NaN.
public func sign <T>(_ x: T) -> T where T: FloatingPoint {
    x > 0 ? 1 : (x < 0 ? -1 : 0)
}

// Returns 0.0 if x <= edge0 and 1.0 if x >= edge1 and performs a smooth Hermite interpolation between 0 and 1 when edge0 < x < edge1. This is useful in cases where you want a threshold function with a smooth transition. This is equivalent to:
// t = clamp((x – edge0)/(edge1 edge0), 0, 1); return t * t * (3 – 2 * t);
// Results are undefined if edge0 >= edge1 or if x, edge0, or edge1 is a NaN.
public func smoothstep <T>(_ edge0: T, _ edge1: T, _ x: T) -> T where T: FloatingPoint {
    let t = clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)
}

// Returns 0.0 if x < edge, otherwise it returns 1.0.
public func step <T>(_ edge: T, _ x: T) -> T where T: FloatingPoint {
    x < edge ? 0 : 1
}

// 6.5 Math Functions

/// Return x with its sign changed to match the sign of y.
public func copysign<T>(x: T, y: T) -> T where T: FloatingPoint {
    y >= .zero ? x : -abs(x)
}

// x – y if x > y; +0 if x <= y.
public func fdim<T>(x: T, y: T) -> T where T: FloatingPoint {
    x > y ? x - y : 0
}

