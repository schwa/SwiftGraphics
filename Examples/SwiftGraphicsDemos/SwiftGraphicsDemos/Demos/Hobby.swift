import CoreGraphicsSupport
import Foundation
import SwiftUI

// swiftlint:disable identifier_name

// From: https://www.jakelow.com/blog/hobby-curves
// https://www.jakelow.com/blog/hobby-curves/hobby.js

// Hobby's algorithm: given a set of points, fit a Bézier spline to them.
// The chosen splines tend to have pleasing, rounded shapes.
//
// Parameters:
//   - points: an array of points as [x, y] pairs
//   - omega: a number between 0 and 1 (inclusive) controls how much curl
//     there will be at the endpoints of the curve
//
// Returns: an array of points as [x, y] pairs that define a Bézier spline.
//
// The output array will have 3n - 2 points where n is the number of input points.
// The output will contain every point in the input (these become knots in the
// Bézier spline), interspersed with pairs of new points which define positions
// of handle points on the spline. All points are in the same coordinate space.
func hobby(points: [CGPoint], omega: Double = 0.0) -> [CGPoint] {
    // solving is only possible if there are at least two points
    assert(points.count >= 2)

    // n is defined such that the points can be numbered P[0] … P[n], i.e. such
    // that there are a total of n+1 points.
    let n = points.count - 1

    // chords[i] is the vector from P[i] to P[i+1].
    // d[i] is the length of the ith chord.
    var chords = Array(repeating: CGPoint.zero, count: n)
    var d = Array(repeating: 0.0, count: n)
    for i in 0 ..< n {
        chords[i] = points[i + 1] - points[i]
        d[i] = chords[i].distance
        // no chord can be zero-length (i.e. no two successive points can be the same)
        assert(d[i] > 0)
    }

    // gamma[i] is the signed turning angle at P[i], i.e. the angle between
    // the chords from P[i-1] to P[i] and from P[i] to P[i+1].
    // gamma[0] is undefined gamma[n] is artificially defined to be zero
    var gamma = Array(repeating: 0.0, count: n + 1)
    for i in 1 ..< n {
        gamma[i] = Angle(from: chords[i - 1], to: chords[i]).radians
    }
    gamma[n] = 0

    // Set up the system of linear equations (Jackowski, formula 38).
    // We're representing this system as a tridiagonal matrix, because
    // we can solve such a system in O(n) time using the Thomas algorithm.
    //
    // Here, A, B, and C are the matrix diagonals and D is the right-hand side.
    // See Wikipedia for a more detailed explanation:
    // https://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm
    var A = Array(repeating: 0.0, count: n + 1)
    var B = Array(repeating: 0.0, count: n + 1)
    var C = Array(repeating: 0.0, count: n + 1)
    var D = Array(repeating: 0.0, count: n + 1)

    B[0] = 2 + omega
    C[0] = 2 * omega + 1
    D[0] = -1 * C[0] * gamma[1]

    for i in 1 ..< n {
        A[i] = 1 / d[i - 1]
        B[i] = (2 * d[i - 1] + 2 * d[i]) / (d[i - 1] * d[i])
        C[i] = 1 / d[i]
        D[i] = (-1 * (2 * gamma[i] * d[i] + gamma[i + 1] * d[i - 1])) / (d[i - 1] * d[i])
    }

    A[n] = 2 * omega + 1
    B[n] = 2 + omega
    D[n] = 0

    // Solve the tridiagonal matrix of equations using the Thomas algorithm,
    // yielding the alpha angles for each point (these are the angles between
    // each chord[i] and the vector c0[i] - P[i], i.e. the vector from knot i
    // to the subsequent control point, which is tangent to the curve at P[i]).
    let alpha = thomas(A, B, C, D)

    // Use alpha (the chord angle) and gamma (the turning angle of the chord
    // polyline) to solve for beta at each point (beta is like alpha, but for
    // the chord and handle vector arriving at P[i] rather than leaving from it).
    var beta = Array(repeating: 0.0, count: n)

    for i in 0 ..< n - 1 {
        beta[i] = -1 * gamma[i + 1] - alpha[i + 1]
    }

    beta[n - 1] = -1 * alpha[n]

    // Now that we have the angles between the handle vector and the chord
    // both arriving at and leaving from each point, we can solve for the
    // positions of the handle (control) points themselves.
    var c0 = Array(repeating: CGPoint.zero, count: n)
    var c1 = Array(repeating: CGPoint.zero, count: n)

    for i in 0 ..< n {
        // Compute the magnitudes of the handle vectors at this point.
        // (Jackowski, formula 22)
        let a = (rho(alpha[i], beta[i]) * d[i]) / 3
        let b = (rho(beta[i], alpha[i]) * d[i]) / 3

        // Use the magnitudes, and the chords and turning angles, to find
        // the positions of the control points in the global coordinate space.
        c0[i] = vAdd(points[i], vScale(vNorm(vRot(chords[i], alpha[i])), a))
        c1[i] = vSub(points[i + 1], vScale(vNorm(vRot(chords[i], -1 * beta[i])), b))
    }

    // Finally, gather up and return the spline points (both knots and
    // control points) as a single ordered list of [x, y] pairs.
    var res = [CGPoint]()

    for i in 0 ..< n {
        res += [points[i], c0[i], c1[i]]
    }
    res.append(points[n])

    return res
}

// Rho is the 'velocity function' that computes the length of the handles for
// the Bézier spline.
//
// Once the angles alpha and beta have been computed for each knot (which
// determine the direction from the knot to each of its neighboring handles),
// this function is used to compute the lengths of the vectors from the knot to
// those handles. Combining the length and angle together lets us solve for the
// handle positions.
//
// The exact choice of function is somewhat arbitrary. The aim is to return
// handle lengths that produce a Bézier curve which is a good approximation of a
// circular arc for points near the knot.
//
// Hobby and Knuth both proposed multiple candidate functions. This code uses
// the function from Jackowski formula 28, due to its simplicity. For other
// choices see Jackowski, section 5.
func rho(_ alpha: Double, _ beta: Double) -> Double {
    let c: Double = 2 / 3
    return 2 / (1 + c * cos(beta) + (1 - c) * cos(alpha))
}

// The Thomas algorithm: solve a system of linear equations encoded in a
// tridiagonal matrix.
//
// https://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm
func thomas(_ A: [Double], _ B: [Double], _ C: [Double], _ D: [Double]) -> [Double] {
    // A, B, and C are diagonals of the matrix. B is the main diagonal.
    // D is the vector on the right-hand-side of the equation.

    // Both B and D will have n elements. The arrays A and C will have
    // length n as well, but each has one fewer element than B (the values
    // A[0] and C[n-1] are undefined).

    // Note: n is defined here so that B[n] is valid, i.e. we are solving
    // a system of n+1 equations.
    let n = B.count - 1

    // Step 1: forward sweep to eliminate A[i] from each equation

    // allocate arrays for modified C and D coefficients
    // (p stands for prime)
    var Cp = [Double](repeating: 0.0, count: n + 1)
    var Dp = [Double](repeating: 0.0, count: n + 1)

    Cp[0] = C[0] / B[0]
    Dp[0] = D[0] / B[0]

    for i in 1 ..< n {
        let denom = B[i] - Cp[i - 1] * A[i]
        Cp[i] = C[i] / denom
        Dp[i] = (D[i] - Dp[i - 1] * A[i]) / denom
    }

    // Step 2: back substitution to solve for X

    var X = [Double](repeating: 0.0, count: n + 1)
    // start at the end, then work backwards to solve for each X[i]
    X[n] = Dp[n]
    for i in stride(from: n - 1, through: 0, by: -1) {
        X[i] = Dp[i] - Cp[i] * X[i + 1]
    }

    return X
}

func vAdd(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    lhs + rhs
}

func vSub(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    lhs - rhs
}

func vNorm(_ point: CGPoint) -> CGPoint {
    let l = point.distance
    return point / l
}

func vRot(_ point: CGPoint, _ angle: Double) -> CGPoint {
    let ca = cos(angle)
    let sa = sin(angle)
    return CGPoint(point.x * ca - point.y * sa, point.x * sa + point.y * ca)
}

func vScale(_ point: CGPoint, _ s: Double) -> CGPoint {
    point * s
}
