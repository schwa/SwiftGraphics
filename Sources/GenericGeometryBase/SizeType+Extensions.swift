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

// TODO: Make static!

// swiftlint:disable static_operator
public func + <Size: SizeType>(lhs: Size, rhs: Size) -> Size {
    Size(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

public func - <Size: SizeType>(lhs: Size, rhs: Size) -> Size {
    Size(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

public func * <Size: SizeType>(lhs: Size, rhs: Size) -> Size {
    Size(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
}

public func / <Size: SizeType>(lhs: Size, rhs: Size) -> Size {
    Size(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
}

public func * <Size: SizeType>(lhs: Size, rhs: Size.Scalar) -> Size {
    Size(width: lhs.width * rhs, height: lhs.height * rhs)
}

public func / <Size: SizeType>(lhs: Size, rhs: Size.Scalar) -> Size {
    Size(width: lhs.width / rhs, height: lhs.height / rhs)
}

public extension SizeType where Scalar: FloatingPoint {
    var area: Scalar {
        abs(signedArea)
    }

    var signedArea: Scalar {
        width * height
    }
}
