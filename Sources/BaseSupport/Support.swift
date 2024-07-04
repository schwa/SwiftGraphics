import Foundation

public extension NSCopying {
    func typedCopy() -> Self {
        // swiftlint:disable force_cast
        self.copy() as! Self
    }
}

public func unimplemented(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError(message(), file: file, line: line)
}

public func temporarilyDisabled(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError(message(), file: file, line: line)
}

public func unreachable(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError(message(), file: file, line: line)
}

public func nextPowerOfTwo(_ value: Double) -> Double {
    let logValue = log2(Double(value))
    return pow(2.0, ceil(logValue))
}

public func nextPowerOfTwo(_ value: Int) -> Int {
    Int(nextPowerOfTwo(Double(value)))
}

public protocol Labeled {
    var label: String? { get }
}

// TODO: Rename to be something less generic.
public struct Box <Content>: Identifiable, Hashable where Content: AnyObject {

    public var id: ObjectIdentifier {
        ObjectIdentifier(content)
    }

    public var content: Content

    public init(_ content: Content) {
        self.content = content
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.content === rhs.content
    }

    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(content).hash(into: &hasher)
    }
}
