import simd

public extension SIMD3 {
    /**
     ```swift doctest
     SIMD3<Float>(1, 2, 3).xy // => SIMD2<Float>(1, 2)
     ```
     */
    var xy: SIMD2<Scalar> {
        get {
            SIMD2(x, y)
        }
        set {
            x = newValue[0]
            y = newValue[1]
        }
    }

    var xz: SIMD2<Scalar> {
        get {
            SIMD2(x, z)
        }
        set {
            x = newValue[0]
            z = newValue[1]
        }
    }

    var yz: SIMD2<Scalar> {
        get {
            SIMD2(y, z)
        }
        set {
            x = newValue[0]
            z = newValue[1]
        }
    }
}

public extension SIMD4 {
    var xy: SIMD2<Scalar> {
        SIMD2(x, y)
    }

    var yz: SIMD2<Scalar> {
        SIMD2(y, z)
    }

    var xz: SIMD2<Scalar> {
        SIMD2(x, z)
    }

    var zy: SIMD2<Scalar> {
        SIMD2(z, y)
    }

    var xyz: SIMD3<Scalar> {
        get {
            SIMD3(x, y, z)
        }
        set {
            self.x = newValue[0]
            self.y = newValue[1]
            self.z = newValue[2]
        }
    }

    var rgb: SIMD3<Scalar> {
        SIMD3(x, y, z)
    }
}

public extension SIMD3 where Scalar: BinaryFloatingPoint {
    init(xz: SIMD2<Scalar>) {
        self = SIMD3(xz[0], 0, xz[1])
    }
}
