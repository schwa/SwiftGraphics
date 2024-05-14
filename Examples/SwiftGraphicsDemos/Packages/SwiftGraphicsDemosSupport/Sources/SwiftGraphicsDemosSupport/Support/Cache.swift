import Foundation
import os

#if os(iOS)
    import UIKit
#endif

class Cache<Key, Value> where Key: Hashable {
    let label: String?

    var lock = OSAllocatedUnfairLock()
    var storage = [Key: Value]()
//    var task: Task<(), Never>?
    var logger: Logger?

    init(label: String? = nil) {
        self.label = label
//        let q = DispatchQueue.init(label: "test")
//        q.async {
//            let source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: nil)
//            source.setEventHandler {
//                let event:DispatchSource.MemoryPressureEvent  = source.mask
//                switch event {
//                case DispatchSource.MemoryPressureEvent.normal:
//                    print("normal")
//                case DispatchSource.MemoryPressureEvent.warning:
//                    print("warning")
//                case DispatchSource.MemoryPressureEvent.critical:
//                    print("critical")
//                default:
//                    break
//                }
//
//            }
//            source.resume()
//        }
//
//        #if os(iOS)
//        task = Task { [weak self] in
//            for await _ in await NotificationCenter.default.notifications(named: UIApplication.didReceiveMemoryWarningNotification) {
//                self?.storage.removeAll()
//            }
//        }
//        #endif
    }

    func get(key: Key) -> Value? {
        lock.withUnsafeLock {
            storage[key]
        }
    }

    func get(key: Key, default: () throws -> Value) rethrows -> Value {
        try lock.withUnsafeLock {
            if let value = storage[key] {
                return value
            }
            else {
//                logger?.info("Cache miss: \(String(describing: key)).")
                let value = try `default`()
                storage[key] = value
                return value
            }
        }
    }

    @discardableResult
    func insert(key: Key, value: Value) -> Value? {
        lock.withUnsafeLock {
            let old = storage[key]
            storage[key] = value
            return old
        }
    }

    @discardableResult
    func remove(key: Key) -> Value? {
        lock.withUnsafeLock {
            let old = storage[key]
            storage[key] = nil
            return old
        }
    }

    func contains(key: Key) -> Bool {
        lock.withUnsafeLock {
            storage[key] != nil
        }
    }

    var allKeys: [Key] {
        lock.withUnsafeLock {
            Array(storage.keys)
        }
    }
}

// MARK: -

extension Cache {
    func get(key: Key, default: () async throws -> Value) async rethrows -> Value {
        let value = lock.withUnsafeLock {
            storage[key]
        }
        if let value {
            return value
        }
        else {
            // TODO: Potential race condition here if storage[key] chanes while `default` is in flight.
            logger?.info("Cache miss: \(String(describing: key)).")
            let value = try await `default`()
            lock.withUnsafeLock {
                storage[key] = value
            }
            return value
        }
    }
}

// MARK: -

extension Cache where Key == String {
    func remove(matching pattern: Regex<String>) throws {
        try lock.withUnsafeLock {
            for key in storage.keys {
                if try pattern.wholeMatch(in: key) != nil {
                    storage[key] = nil
                }
            }
        }
    }
}

extension Cache where Value == Any {
    func get<T>(key: Key, of: T.Type, default: () throws -> T) rethrows -> T {
        try get(key: key, default: `default`) as! T
    }
}

extension OSAllocatedUnfairLock where State == () {
    func withUnsafeLock<R>(_ block: () throws -> R) rethrows -> R {
        lock()
        defer {
            unlock()
        }
        return try block()
    }
}

// MARK: -

// TODO: not sure if this is a good idea but idea is for factory functions to return Cachable objects so that the key is separate from the value. Useful for returning objects with no key as part of the value (e.g. raw Data, Meshes etc).
struct Cachable<Key, Value> where Key: Hashable & Sendable {
    var key: Key
    var value: Value

    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

extension Cachable: Identifiable {
    var id: Key {
        key
    }
}

extension Cache {
    @discardableResult
    func insert(_ cachable: Cachable<Key, Value>) -> Value? {
        insert(key: cachable.key, value: cachable.value)
    }
}

extension Cache where Value == Any {
    @discardableResult
    func insert<V>(_ cachable: Cachable<Key, V>) -> V? {
        insert(key: cachable.key, value: cachable.value) as? V
    }
}
