public struct SlopeInterceptForm: Equatable {
    public var m, b: Double

    public init(m: Double, b: Double) {
        self.m = m
        self.b = b
    }
}

// public extension SlopeInterceptForm {
//    var isHorizontal: Bool {
//        m == 0
//    }
//
//    var isVertical: Bool {
//        false
//    }
//
//    var xIntercept: CGPoint? {
//        m == 0 ? nil : CGPoint(-b / m, 0)
//    }
//
//    var yIntercept: CGPoint? {
//        CGPoint(0, b)
//    }
//
//    var slope: Double {
//        m
//    }
// }

// MARK: Conversion between SlopeIntercept and Standard Form

public extension Line {
    init(slopeInterceptForm: SlopeInterceptForm) {
        self = .init(slopeInterceptFormToStandardForm(m: slopeInterceptForm.m, b: slopeInterceptForm.b))
    }

    var slopeInterceptForm: SlopeInterceptForm? {
        get {
            guard let (m, b) = standardFormSlopeInterceptFormTo(a: a, b: b, c: c) else {
                return nil
            }
            return .init(m: m, b: b)
        }
        set {
            guard let newValue else {
                fatalError()
            }
            self = .init(slopeInterceptForm: newValue)
        }
    }
}

func slopeInterceptFormToStandardForm(m: Double, b: Double) -> (a: Double, b: Double, c: Double) {
    (a: -m, b: 1, c: b)
}

func standardFormSlopeInterceptFormTo(a: Double, b: Double, c: Double) -> (m: Double, b: Double)? {
    guard b != 0 else {
        return nil
    }
    return (m: -a / b, b: c / b)
}

public extension SlopeInterceptForm {
    init(_ tuple: (m: Double, b: Double)) {
        self = .init(m: tuple.m, b: tuple.b)
    }

    var tuple: (m: Double, b: Double) {
        (m: m, b: b)
    }
}
