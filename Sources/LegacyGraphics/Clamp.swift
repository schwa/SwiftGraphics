// Generic clamp()

// TODO: Move

public func clamp<T>(_ value: T, lower: T, upper: T) -> T where T: Comparable {
    max(min(value, upper), lower)
}

public func clamp<T>(_ value: T, in range: ClosedRange<T>) -> T where T: Comparable {
    min(max(value, range.lowerBound), range.upperBound)
}
