import CoreGraphics

public struct SlopeInterceptForm: Equatable {
    public var m, b: Double

    public init(m: Double, b: Double) {
        self.m = m
        self.b = b
    }
}

public extension SlopeInterceptForm {
    var isHorizontal: Bool {
        m == 0
    }

    var isVertical: Bool {
        false
    }

    var xIntercept: CGPoint? {
        m == 0 ? nil : CGPoint(-b / m, 0)
    }

    var yIntercept: CGPoint? {
        CGPoint(0, b)
    }

    var slope: Double {
        m
    }
}

// MARK: Conversion between SlopeIntercept and Standard Form

public extension Line {

    static func slopeIntercept(m: Double, b: Double) -> Line {
        .init(a: -m, b: 1, c: b)
    }

    init(slopeInterceptForm: SlopeInterceptForm) {
        self = .init(a: -slopeInterceptForm.m, b: 1, c: slopeInterceptForm.b)
    }

    var slopeInterceptForm: SlopeInterceptForm? {
        get {
            guard b != 0 else {
                return nil
            }
            return .init(m: -a / b, b: c / b)
        }
        set {
            guard let newValue else {
                fatalError("Cannot set slopeInterceptForm to nil")
            }
            self = .init(slopeInterceptForm: newValue)
        }
    }
}

public extension SlopeInterceptForm {
    init(_ tuple: (m: Double, b: Double)) {
        self = .init(m: tuple.m, b: tuple.b)
    }

    var tuple: (m: Double, b: Double) {
        (m: m, b: b)
    }
}
