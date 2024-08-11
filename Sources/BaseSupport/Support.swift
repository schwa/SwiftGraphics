import Foundation
#if os(macOS)
import AppKit
#endif

public extension NSCopying {
    func typedCopy() -> Self {
        // swiftlint:disable force_cast
        self.copy() as! Self
    }
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

public extension Box {
    func callAsFunction() -> Content {
        content
    }
}

extension Box: Sendable where Content: Sendable {
}

public extension Array {
    var mutableLast: Element? {
        get {
            last
        }
        set {
            precondition(last != nil)
            if let newValue {
                self[index(before: endIndex)] = newValue
            } else {
                _ = popLast()
            }
        }
    }
}

public extension URL {
    func reveal() {
        #if os(macOS)
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        #endif
    }
}

public func align(_ value: Int, alignment: Int) -> Int {
    (value + alignment - 1) / alignment * alignment
}

public func getMachTimeInNanoseconds() -> UInt64 {
    var timebase = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    let currentTime = mach_absolute_time()
    return currentTime * UInt64(timebase.numer) / UInt64(timebase.denom)
}

@discardableResult
public func timeit<R>(_ label: String? = nil, _ block: () throws -> R) rethrows -> R {
    let start = getMachTimeInNanoseconds()
    let result = try block()
    let end = getMachTimeInNanoseconds()
    let delta = TimeInterval(end - start) / 1_000_000_000

    let measurement = Measurement(value: delta, unit: UnitDuration.seconds)
    let measurementMS = measurement.converted(to: .milliseconds)

    print("\(label ?? "<unamed>"): \(measurementMS.formatted())")
    return result
}
