import os
import SwiftUI

public struct RenderErrorHandler: Sendable {
    var handler: @Sendable (Error) -> Void

    public init(handler: @Sendable @escaping (Error) -> Void = { _ in }) {
        self.handler = handler
    }

    public func send(_ error: Error, logger: Logger? = nil) {
        if let logger {
            logger.error("\(error)")
            handler(error)
        }
    }
}

public struct RenderErrorHandlerKey: EnvironmentKey {
    public static let defaultValue = RenderErrorHandler()
}

public extension EnvironmentValues {
    var renderErrorHandler: RenderErrorHandler {
        get {
            self[RenderErrorHandlerKey.self]
        }
        set {
            self[RenderErrorHandlerKey.self] = newValue
        }
    }
}

public extension View {
    func renderErrorHandler(_ handler: @Sendable @escaping (Error) -> Void) -> some View {
        environment(\.renderErrorHandler, .init(handler: handler))
    }
}
