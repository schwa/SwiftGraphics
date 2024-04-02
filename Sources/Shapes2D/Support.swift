import Foundation

internal extension ComparisonResult {
    static func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs == rhs {
            .orderedSame
        }
        else if lhs < rhs {
            .orderedAscending
        }
        else {
            .orderedDescending
        }
    }
}

