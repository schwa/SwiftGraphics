import os
import SwiftUI

struct RenderErrorHandler: Sendable {
    var handler: @Sendable (Error) -> Void

    init(handler: @Sendable @escaping (Error) -> Void = { _ in }) {
        self.handler = handler
    }

    func send(_ error: Error, logger: Logger? = nil) {
        if let logger {
            logger.error("\(error)")
            handler(error)
        }
    }
}

struct RenderErrorHandlerKey: EnvironmentKey {
    static let defaultValue = RenderErrorHandler()
}

extension EnvironmentValues {
    var renderErrorHandler: RenderErrorHandler {
        get {
            self[RenderErrorHandlerKey.self]
        }
        set {
            self[RenderErrorHandlerKey.self] = newValue
        }
    }
}

struct RenderErrorHandlerModifier: ViewModifier {
    let value: RenderErrorHandler
    func body(content: Content) -> some View {
    }
}

public extension View {
    func renderErrorHandler(_ handler: @Sendable @escaping (Error) -> Void) -> some View {
        environment(\.renderErrorHandler, .init(handler: handler))
    }
}
