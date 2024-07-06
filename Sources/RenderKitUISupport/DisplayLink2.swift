#if os(macOS)
import AppKit
import QuartzCore
#else
import UIKit
#endif
import SwiftUI

// TODO: Use UIUpdateLink

@available(macOS 14, iOS 15, tvOS 16, *)
class DisplayLink2 {
    struct Event {
        var timestamp: CFTimeInterval
        var duration: CFTimeInterval
    }

    private class Helper: NSObject, @unchecked Sendable {
        var continuations: [UUID: AsyncStream<Event>.Continuation] = [:]

        deinit {
            for value in continuations.values {
                value.finish()
            }
        }

        @objc func callCallback(_ displayLink: CADisplayLink) {
            for continuation in continuations.values {
                continuation.yield(Event(timestamp: displayLink.timestamp, duration: displayLink.duration))
            }
        }
    }

    private let runloop: RunLoop
    private let mode: RunLoop.Mode
    private let helper: Helper
    private let displayLink: CADisplayLink

    var isPaused: Bool {
        get {
            displayLink.isPaused
        }
        set {
            displayLink.isPaused = newValue
        }
    }

    private init(runloop: RunLoop = .current, mode: RunLoop.Mode = .default, displayLinkFactory: (Helper) -> CADisplayLink) {
        self.runloop = runloop
        self.mode = mode
        helper = Helper()
        displayLink = displayLinkFactory(helper)
        displayLink.add(to: .current, forMode: .default)
    }

    deinit {
        self.displayLink.invalidate()
    }

    convenience init(runloop: RunLoop = .current, mode: RunLoop.Mode = .default) {
        #if os(macOS)
        self.init(runloop: runloop, mode: mode, source: NSScreen.screens[0])
        #else
        self.init(runloop: runloop, mode: mode) {
            CADisplayLink(target: $0, selector: #selector(Helper.callCallback))
        }
        #endif
    }

    func events() -> AsyncStream<Event> {
        let (stream, continuation) = AsyncStream.makeStream(of: Event.self)
        let id = UUID()
        helper.continuations[id] = continuation
        continuation.onTermination = { @Sendable [weak helper] _ in
            helper?.continuations[id] = nil
        }
        return stream
    }
}

#if os(macOS)
@available(macOS 14, iOS 15, tvOS 16, *)
extension DisplayLink2 {
    convenience init(runloop: RunLoop = .current, mode: RunLoop.Mode = .default, source: NSScreen) {
        self.init(runloop: runloop, mode: mode) {
            source.displayLink(target: $0, selector: #selector(Helper.callCallback))
        }
    }

    @MainActor
    convenience init(runloop: RunLoop = .current, mode: RunLoop.Mode = .default, source: NSWindow) {
        self.init(runloop: runloop, mode: mode) {
            source.displayLink(target: $0, selector: #selector(Helper.callCallback))
        }
    }

    @MainActor
    convenience init(runloop: RunLoop = .current, mode: RunLoop.Mode = .default, source: NSView) {
        self.init(runloop: runloop, mode: mode) {
            source.displayLink(target: $0, selector: #selector(Helper.callCallback))
        }
    }
}
#endif

@available(macOS 14, iOS 15, tvOS 16, *)
struct DisplayLinkKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: DisplayLink2 = .init()
}

@available(macOS 14, iOS 15, tvOS 16, *)
extension EnvironmentValues {
    var displayLink: DisplayLink2 {
        get {
            self[DisplayLinkKey.self]
        }
        set {
            self[DisplayLinkKey.self] = newValue
        }
    }
}

@available(macOS 14, iOS 15, tvOS 16, *)
extension View {
    func displayLink(_ displayLink: DisplayLink2) -> some View {
        environment(\.displayLink, displayLink)
    }
}
