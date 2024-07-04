public struct AnyEquatable: Equatable {
    let value: Any
    let equals: (Any) -> Bool

    public init<E: Equatable>(_ value: E) {
        self.value = value
        self.equals = { ($0 as? E) == value }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.equals(rhs.value)
    }
}
