public struct Pair<LHS, RHS> {
    public var lhs: LHS
    public var rhs: RHS

    public init(_ lhs: LHS, _ rhs: RHS) {
        self.lhs = lhs
        self.rhs = rhs
    }
}

extension Pair: Equatable where LHS: Equatable, RHS: Equatable {
}

extension Pair: Hashable where LHS: Hashable, RHS: Hashable {
}

extension Pair: Sendable where LHS: Sendable, RHS: Sendable {
}

public extension Pair where LHS == RHS {
    mutating func swapped() {
        swap(&lhs, &rhs)
    }
}

// extension Pair where LHS == RHS, LHS: Equatable, RHS: Equatable {
//    mutating func sorted() {
//        if lhs < rhs {
//            swap(&lhs, &rhs)
//        }
//    }
// }

public extension Pair {
    func sorted() -> Pair<LHS, RHS> where LHS == RHS, LHS: Comparable {
        var copy = self
        if lhs >= rhs {
            swap(&copy.lhs, &copy.rhs)
        }
        return copy
    }
}

public extension Pair {
    init(_ value: (LHS, RHS)) {
        lhs = value.0
        rhs = value.1
    }
}

public extension Pair where LHS == RHS {
    func reversed() -> Pair<RHS, LHS> {
        .init(rhs, lhs)
    }
}

// extension Pair: Equatable where LHS: Equatable, RHS: Equatable {
// }
//
// extension Pair: Hashable where LHS: Hashable, RHS: Hashable {
// }
//
// extension Pair: CustomDebugStringConvertible where LHS: CustomDebugStringConvertible, RHS: CustomDebugStringConvertible {
//    var debugDescription: String {
//        "(\(lhs), \(rhs))"
//    }
// }
