import CoreGraphics

public extension SizeType {
    init(_ width: Scalar, _ height: Scalar) {
        self.init(width: width, height: height)
    }

    static var zero: Self {
        self.init(width: Scalar(0), height: Scalar(0))
    }
}

// MARK: -

public extension SizeType where Scalar: FloatingPoint {
    var area: Scalar {
        abs(signedArea)
    }

    var signedArea: Scalar {
        width * height
    }
}
