import Foundation
import simd
@testable import SIMDSupport
import XCTest

public func XCTAssertEqual<T>(_ expression1: @escaping @autoclosure () throws -> [T], _ expression2: @escaping @autoclosure () throws -> [T], accuracy: T, _ message: @escaping @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) where T: Numeric {
    XCTAssertNoThrow {
        try zip(expression1(), expression2()).forEach {
            XCTAssertEqual($0, $1, accuracy: accuracy, message(), file: file, line: line)
        }
    }
}

public func XCTAssertNotEqual<T>(_ expression1: @escaping @autoclosure () throws -> [T], _ expression2: @escaping @autoclosure () throws -> [T], accuracy: T, _ message: @escaping @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) where T: Numeric {
    do {
        let value1 = try expression1()
        let value2 = try expression2()
        let values = zip(value1, value2)
        for (value1, value2) in values {
            XCTAssertNotEqual(value1, value2, accuracy: accuracy, message(), file: file, line: line)
        }
    }
    catch {
        XCTAssert(false, "Oops")
    }
}

class TestNewAsserts: XCTestCase {
    func test1() {
        XCTAssertEqual([0.1, 0.1], [0, 0], accuracy: 0.1)
        XCTAssertNotEqual([0.1, 0.1], [0, 0], accuracy: 0)
    }
}

// MARK: -

public func XCTAssertEqual(_ expression1: @escaping @autoclosure () throws -> simd_float4x4, _ expression2: @escaping @autoclosure () throws -> simd_float4x4, accuracy: Float, _ message: @escaping @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(try expression1().scalars, try expression2().scalars, accuracy: accuracy, message(), file: file, line: line)
}

public func XCTAssertEqual<Scalar>(
    _ expression1: @escaping @autoclosure () throws -> Euler<Scalar>,
    _ expression2: @escaping @autoclosure () throws -> Euler<Scalar>,
    accuracy: Scalar,
    _ message: @escaping @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) where Scalar: SIMDScalar & BinaryFloatingPoint {
    XCTAssertEqual(try expression1().scalars, try expression2().scalars, accuracy: accuracy, message(), file: file, line: line)
}

public func XCTAssertNotEqual<Scalar>(
    _ expression1: @escaping @autoclosure () throws -> Euler<Scalar>,
    _ expression2: @escaping @autoclosure () throws -> Euler<Scalar>,
    accuracy: Scalar,
    _ message: @escaping @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) where Scalar: SIMDScalar & BinaryFloatingPoint {
    XCTAssertNotEqual(try expression1().scalars, try expression2().scalars, accuracy: accuracy, message(), file: file, line: line)
}
