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

// TODO: Stop being CG based

public extension SizeType where Scalar: FloatingPoint {
    var area: Scalar {
        abs(signedArea)
    }

    var signedArea: Scalar {
        width * height
    }
}

// TODO: Move elsewhere? Rename AreaOrientation?
public enum Orientation {
    case square
    case landscape
    case portrait
}

public extension CGSize {
    var aspectRatio: CGFloat {
        width / height
    }

    var orientation: Orientation {
        if abs(width) > abs(height) {
            .landscape
        }
        else if abs(width) == abs(height) {
            .square
        }
        else {
            .portrait
        }
    }

    func toRect() -> CGRect {
        CGRect(size: self)
    }
}

public extension CGSize {
    init(_ v: (CGFloat, CGFloat)) {
        self.init(width: v.0, height: v.1)
    }

    func toTuple() -> (CGFloat, CGFloat) {
        (width, height)
    }
}

public extension CGSize {
    var min: CGFloat {
        Swift.min(width, height)
    }

    var max: CGFloat {
        Swift.max(width, height)
    }
}
