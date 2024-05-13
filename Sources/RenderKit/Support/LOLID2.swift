import Foundation
import os

public struct LOLID2: Hashable, Sendable {
    private static let nextIndexByPrefix = OSAllocatedUnfairLock(initialState: [String: Int]())

    public static func generate(prefix: String) -> Self {
        nextIndexByPrefix.withLock { nextIndexByPrefix in
            let index = nextIndexByPrefix[prefix, default: 0]
            let id = LOLID2(rawValue: "\(prefix)-\(index)")
            nextIndexByPrefix[prefix] = index + 1
            return id
        }
    }

    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(prefix: String) {
        self = LOLID2.generate(prefix: prefix)
    }
}

extension LOLID2: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
