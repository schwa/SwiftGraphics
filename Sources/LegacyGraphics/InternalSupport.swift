import Foundation

func equal(_ lhs: CGFloat, _ rhs: CGFloat, accuracy: CGFloat) -> Bool {
    abs(rhs - lhs) <= accuracy
}

func equal(_ lhs: Float, _ rhs: Float, accuracy: Float) -> Bool {
    abs(rhs - lhs) <= accuracy
}

func equal(_ lhs: Double, _ rhs: Double, accuracy: Double) -> Bool {
    abs(rhs - lhs) <= accuracy
}

protocol FuzzyEquatable {
    static func isFuzzyEqual(_ lhs: Self, _ rhs: Self) -> Bool
}

// MARK: Fuzzy inequality

// MARK: Float

func isFuzzyEqual(_ lhs: Float, _ rhs: Float) -> Bool {
    equal(lhs, rhs, accuracy: .ulpOfOne)
}

// MARK: Double

func isFuzzyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
    equal(lhs, rhs, accuracy: .ulpOfOne)
}

// MARK: CGPoint

func isFuzzyEqual(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
    isFuzzyEqual(lhs.x, rhs.x) && isFuzzyEqual(lhs.y, rhs.y)
}
