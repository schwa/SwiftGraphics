struct CompositeHash <each T: Hashable>: Hashable {
    private let children: (repeat each T)

    init(_ children: repeat each T) {
        self.children = (repeat each children)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        for (left, right) in repeat (each lhs.children, each rhs.children) {
            guard left == right else {
                return false
            }
        }
        return true
    }

    func hash(into hasher: inout Hasher) {
        for child in repeat (each children) {
            child.hash(into: &hasher)
        }
    }
}

extension CompositeHash: Sendable where repeat each T: Sendable {
}
