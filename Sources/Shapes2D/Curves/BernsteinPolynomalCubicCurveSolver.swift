import simd

public struct BernsteinPolynomalCubicCurveSolver {
    var controlPoints: (Double, Double, Double, Double)
    var cm: SIMD4<Double>
    var tf: Double

    // Use tf = 1
    public static let bezier = simd_double4x4(columns: (
        [1, 0, 0, 0],
        [-3, 3, 0, 0],
        [3, -6, 3, 0],
        [-1, 3, -3, 1]
    )
    )

    // Use tf = 1/2
    public static let catmullRom = simd_double4x4(columns: (
        [0, 2, 0, 0],
        [-1, 0, 1, 0],
        [2, -5, 4, -1],
        [-1, 3, -3, 1]
    )
    )

    // Use tf = 1/6
    public static let bSpline = simd_double4x4(columns: (
        [1, 4, 1, 0],
        [-3, 0, 3, 0],
        [3, -6, 3, 0],
        [-1, 3, -3, 1]
    )
    )

    public init(controlPoints: (Double, Double, Double, Double), m: simd_double4x4 = Self.bezier, tf: Double = 1) {
        self.controlPoints = controlPoints
        let cp = controlPoints
        let c = SIMD4<Double>(cp.0, cp.1, cp.2, cp.3)
        self.tf = tf
        cm = c * m
    }

    public func sample_cubic_matrix(t: Double) -> Double {
        let t = SIMD4<Double>(1, t, t * t, t * t * t) * tf
        return (cm * t).sum()
    }

    public func sample_cubic(t: Double) -> Double {
        let (P₀, P₁, P₂, P₃) = controlPoints
        let t² = t * t
        let t³ = t² * t
        let P = P₀ * (-t³ + 3 * t² - 3 * t + 1)
            + P₁ * (3 * t³ - 6 * t² + 3 * t)
            + P₂ * (-3 * t³ + 3 * t²)
            + P₃ * t³
        return P
    }
}
