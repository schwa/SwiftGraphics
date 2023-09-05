//
//  File.swift
//  
//
//  Created by Jonathan Wight on 9/16/23.
//

import Foundation
import Algorithms

public extension Collection {
    func pairs() -> [(Element, Element?)] {
        chunks(ofCount: 2).map {
            let a = Array($0)
            return (a[0], a.count == 2 ? a[1] : nil)
        }
    }
}

public func equal(_ lhs: CGFloat, _ rhs: CGFloat, accuracy: CGFloat) -> Bool {
    abs(rhs - lhs) <= accuracy
}

public func equal(_ lhs: Float, _ rhs: Float, accuracy: Float) -> Bool {
    abs(rhs - lhs) <= accuracy
}

public func equal(_ lhs: Double, _ rhs: Double, accuracy: Double) -> Bool {
    abs(rhs - lhs) <= accuracy
}

public protocol FuzzyEquatable {
    static func ==% (lhs: Self, rhs: Self) -> Bool
}

infix operator ==%: ComparisonPrecedence

// MARK: Fuzzy inequality

infix operator !=%: ComparisonPrecedence

// swiftlint:disable:next static_operator
public func !=% <T: FuzzyEquatable>(lhs: T, rhs: T) -> Bool {
    !(lhs ==% rhs)
}

// MARK: Float

extension Float: FuzzyEquatable {
    public static func ==% (lhs: Float, rhs: Float) -> Bool {
        equal(lhs, rhs, accuracy: .ulpOfOne)
    }
}

// MARK: Double

extension Double: FuzzyEquatable {
    public static func ==% (lhs: Double, rhs: Double) -> Bool {
        equal(lhs, rhs, accuracy: .ulpOfOne)
    }
}

// MARK: CGFloat

extension CGFloat: FuzzyEquatable {
    public static func ==% (lhs: CGFloat, rhs: CGFloat) -> Bool {
        equal(lhs, rhs, accuracy: .ulpOfOne)
    }
}

// MARK: CGPoint

extension CGPoint: FuzzyEquatable {
    public static func ==% (lhs: CGPoint, rhs: CGPoint) -> Bool {
        lhs.x ==% rhs.x && lhs.y ==% rhs.y
    }
}
