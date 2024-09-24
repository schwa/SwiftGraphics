import os

final class Pool <T>: Sendable where T: Sendable {
    let elements: OSAllocatedUnfairLock<[T]> = .init(initialState: [])
    let highWaterCount: OSAllocatedUnfairLock = .init(initialState: 0)
    let logger: Logger? = .init()

    init() {
    }

    func clear() {
        elements.withLock { elements in
            elements = []
        }
    }

    private func push(element: T) {
        elements.withLock { elements in
            elements.append(element)
            let count = elements.count
            let highWaterCount: Int? = self.highWaterCount.withLock { highWaterCount in
                if count > highWaterCount {
                    highWaterCount = count
                    return highWaterCount
                }
                return nil
            }
            if let highWaterCount {
                logger?.log("High water mark: \(highWaterCount)")
            }
        }
    }

    private func pop(default: @Sendable () -> T) -> T {
        elements.withLock { elements in
            elements.popLast() ?? `default`()
        }
    }

    func withElement <R>(default: @autoclosure @Sendable () -> T, _ closure: (T) throws -> R) rethrows -> R {
        let element = pop(default: `default`)
        defer {
            push(element: element)
        }
        return try closure(element)
    }

    func withMutableElement <R>(default: @autoclosure @Sendable () -> T, _ closure: (inout T) throws -> R) rethrows -> R {
        var element = pop(default: `default`)
        defer {
            push(element: element)
        }
        return try closure(&element)
    }
}
