import Foundation
import os

// TODO: Make generic (will have to move staticState out of struct)
public struct TrivialID: Sendable, Hashable {
    struct StaticState {
        var scopesByName: [String: Scope] = [:]
        var nextSerials: [Scope: Int] = [:]
    }

    private static let staticState: OSAllocatedUnfairLock<StaticState> = .init(initialState: .init())

    public struct Scope: Sendable, Hashable {
        public private(set) var name: String
        var token: Int

        init(name: String, token: Int = .random(in: 0...0xFFFFFF)) {
            self.name = name
            self.token = token
        }
    }

    static func scope(for name: String) -> Scope {
        Self.staticState.withLock { staticState in
            let scope = staticState.scopesByName[name, default: .init(name: name)]
            staticState.scopesByName[name] = scope
            return scope
        }
    }

    public private(set) var scope: Scope
    public private(set) var serial: Int

    private init(scope: Scope, serial: Int) {
        self.scope = scope
        self.serial = serial
    }

    public init(scope name: String = "") {
        self = Self.staticState.withLock { staticState in
            let scope = staticState.scopesByName[name, default: .init(name: name)]
            let serial = staticState.nextSerials[scope, default: 0] + 1
            staticState.scopesByName[name] = scope
            staticState.nextSerials[scope] = serial
            return .init(scope: scope, serial: serial)
        }
    }

    public init<T>(for type: T.Type) {
        self = Self(scope: String(describing: type))
    }

    public static func dump() {
        staticState.withLock { staticState in
            debugPrint(staticState)
        }
    }
}

extension TrivialID: CustomStringConvertible {
    public var description: String {
        if scope.name.isEmpty {
            return "#\(serial)"
        }
        else {
            return "\(scope.name):#\(serial)"
        }
    }
}

extension TrivialID: CustomDebugStringConvertible {
    public var debugDescription: String {
        "TrivialID(scope: \(scope), serial: \(serial))"
    }
}

/// Decoding a TrivialID is potentially a bad idea and can lead to ID conflicts if IDs have already been generated using the same scope.
extension TrivialID: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        let pattern = #/^(?<scopeName>.+)\.(?<scopeToken>.+):(?<serial>\d+)$/#
        guard let match = string.wholeMatch(of: pattern) else {
            fatalError("Could not decode TrivialID")
        }
        guard let scopeToken = Int(match.output.scopeToken, radix: 16) else {
            fatalError("Could not decode scope token")
        }
        guard let serial = Int(match.output.serial) else {
            fatalError("Could not decode serial")
        }
        let scope = Scope(name: String(match.output.scopeName), token: scopeToken)
        TrivialID.staticState.withLock { staticState in
            if staticState.scopesByName[scope.name] == nil {
                staticState.scopesByName[scope.name] = scope
            }
            staticState.nextSerials[scope] = max(staticState.nextSerials[scope, default: 0], serial)
        }
        self = .init(scope: scope, serial: serial)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(scope.name).\(String(scope.token, radix: 16)):\(serial)")
    }
}

extension TrivialID.Scope: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(name).\(String(token, radix: 16))"
    }
}
