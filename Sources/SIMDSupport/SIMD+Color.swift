import simd

public extension SIMD3 {
    var red: Scalar {
        get {
            x
        }
        set {
            x = newValue
        }
    }

    var green: Scalar {
        get {
            y
        }
        set {
            y = newValue
        }
    }

    var blue: Scalar {
        get {
            z
        }
        set {
            z = newValue
        }
    }
}
