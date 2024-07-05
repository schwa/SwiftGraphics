import Foundation

public extension Task where Failure == Error {
    @discardableResult
    static func delayed(byTimeInterval delayInterval: TimeInterval, priority: TaskPriority? = nil, operation: @escaping @Sendable () async throws -> Success) -> Task {
        Task(priority: priority) {
            let delay = UInt64(delayInterval * 1_000_000_000)
            try await Task<Never, Never>.sleep(nanoseconds: delay)
            // TODO: Check cancellation
            return try await operation()
        }
    }

    @discardableResult
    static func scheduled(at date: Date, priority: TaskPriority? = nil, operation: @escaping @Sendable () async throws -> Success) async -> Task {
        let now = Date()
        return Task(priority: priority) {
            let interval = date.timeIntervalSince(now)
            await withCheckedContinuation { continuation in
                Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                    continuation.resume()
                }
            }
            // TODO: Check cancellation
            return try await operation()
        }
    }
}
