import AsyncAlgorithms
import Foundation
import GameController
import Observation
import SwiftUI

// TODO: This needs to be massively cleaned-up and turned into an actor.
// TODO: We need good support for pausing/resuming inputs
// TODO: we need to be able to reliably find devices and handle disconnect/reconnect gracefully
// TODO: So many retain cycles here.
// TODO: Break into smaller actors (one for kb/mouse/gcs)
// TODO: That notification thing is f-ing hideous
@Observable
class MovementController: @unchecked Sendable {
    struct Event {
        enum Payload {
            case movement(SIMD3<Float>)
            case rotation(Float)
        }

        var payload: Payload
        var created = CFAbsoluteTimeGetCurrent()

        static func movement(_ movement: SIMD3<Float>) -> Self {
            .init(payload: .movement(movement))
        }

        static func rotation(_ rotation: Float) -> Self {
            .init(payload: .rotation(rotation))
        }
    }

    var focused = false

    @ObservationIgnored
    var displayLink: DisplayLink2?

    @ObservationIgnored
    var controller: GCController? {
        didSet {
            logger?.log("Controller did change.")
            capturedControllerProfile = controller?.physicalInputProfile.capture()
        }
    }

    @ObservationIgnored
    var capturedControllerProfile: GCPhysicalInputProfile? {
        didSet {
            move = capturedControllerProfile?.axes[GCElementKey.leftThumbstickYAxis.rawValue]
            strafe = capturedControllerProfile?.axes[GCElementKey.leftThumbstickXAxis.rawValue]
            turn = capturedControllerProfile?.axes[GCElementKey.rightThumbstickXAxis.rawValue]
        }
    }

    @ObservationIgnored
    var move: GCControllerAxisInput?
    @ObservationIgnored
    var strafe: GCControllerAxisInput?
    @ObservationIgnored
    var turn: GCControllerAxisInput?

    @ObservationIgnored
    let channel = AsyncChannel<Event>()

    //    var lastMouseUpdate: TimeInterval = 0

    func disableUIKeys() {
#if os(macOS)
        logger?.debug("NSEvent.addLocalMonitorForEvents(matching: .keyDown) …")
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // If we're not focused return everything.
            guard self?.focused == true else {
                logger?.debug("Ignoring event, not focused.")
                return event
            }
            // If a modifier is down
            guard event.modifierFlags.isDisjoint(with: [.command, .shift, .control, .option]) else {
                logger?.debug("Ignoring event, modifier down.")
                return event
            }
            // If we're not a WASD key
            guard ["w", "a", "s", "d"].contains(event.characters) else {
                logger?.debug("Ignoring key that wasn't a movement key.")
                return event
            }
            logger?.debug("Got movement key.")
            // Consume the key
            return nil
        }
#endif
    }

    @ObservationIgnored
    var mouse: GCMouse? {
        willSet {
            mouse?.mouseInput?.mouseMovedHandler = nil
        }
        didSet {
            mouse?.handlerQueue = DispatchQueue(label: "Mouse", qos: .userInteractive)
            mouse?.mouseInput?.mouseMovedHandler = { [weak self] _, x, y in
                guard let self else {
                    return
                }
                guard x != 0 || y != 0 else {
                    logger?.debug("Ignoring event, no movement.")
                    return
                }
                guard self.focused == true else {
                    logger?.debug("Ignoring event, not focused.")
                    return
                }
                //                strongSelf.mouseMovement += SIMD2(x, y)
                //                Counters.shared.increment(counter: "Mouse (Delta)")
                Task {
                    Counters.shared.increment(counter: "Mouse Moved")
                    await self.channel.send(.rotation(x))
                }
            }
        }
    }

    @ObservationIgnored
    var keyboardTask: Task<Void, Never>?

    @ObservationIgnored
    var relayTask: Task<Void, Never>?

    @ObservationIgnored
    var controllerNotificationsTask: Task<Void, Never>?

    init(displayLink: DisplayLink2) {
        self.displayLink = displayLink
        keyboard()
    }

    func events() -> AsyncChannel<Event> {
        controllerNotificationsTask = Task { [weak self] in
            await withDiscardingTaskGroup { [weak self] group in
                let notificationCenter = NotificationCenter.default
                group.addTask { [weak self] in
                    for await controller in notificationCenter.notifications(named: .GCControllerDidBecomeCurrent).compactMap(\.object).cast(to: GCController.self) {
                        self?.controller = controller
                    }
                }
                group.addTask { [weak self] in
                    for await controller in notificationCenter.notifications(named: .GCControllerDidDisconnect).compactMap(\.object).cast(to: GCController.self) where self?.controller === controller {
                        self?.controller = nil
                    }
                }
                group.addTask { [weak self] in
                    for await mouse in notificationCenter.notifications(named: .GCMouseDidConnect).compactMap(\.object).cast(to: GCMouse.self) {
                        self?.mouse = mouse
                    }
                }
                group.addTask { [weak self] in
                    for await mouse in notificationCenter.notifications(named: .GCMouseDidDisconnect).compactMap(\.object).cast(to: GCMouse.self) where self?.mouse === mouse {
                        self?.mouse = nil
                    }
                }
            }
        }

        relayTask = Task { [weak self] in
            let events = self?.displayLink!.events().flatMap { [weak self] _ in
                Counters.shared.increment(counter: "DisplayLink")
                return (self?.makeEvent() ?? []).async
            }
            guard let events else {
                return
            }
            for await event in events {
                Counters.shared.increment(counter: "Relay")
                await self?.channel.send(event)
            }
        }
        return channel
    }

    func keyboard() {
        keyboardTask = Task { [weak self] in
            guard let displayLink = self?.displayLink else {
                return
            }
            // TODO: Move to MovementController
            // TODO: FIXME

            //            for await _ in NotificationCenter.default.notifications(named: .GCKeyboardDidConnect) {
            //                break
            //            }
            guard let keyboard = GCKeyboard.coalesced, let keyboardInput = keyboard.keyboardInput else {
                return
            }
            let capturedInput = keyboardInput.capture()
            let leftGUI = capturedInput.button(forKeyCode: .leftGUI)!
            let keyW = capturedInput.button(forKeyCode: .keyW)!
            let keyA = capturedInput.button(forKeyCode: .keyA)!
            let keyS = capturedInput.button(forKeyCode: .keyS)!
            let keyD = capturedInput.button(forKeyCode: .keyD)!

            for await _ in displayLink.events() {
                guard self?.focused == true else {
                    logger?.debug("Skipping event, not focused")
                    return
                }
                capturedInput.setStateFromPhysicalInput(keyboardInput)
                if leftGUI.value > 0 {
                    continue
                }
                var delta = SIMD2<Float>.zero
                if keyW.value > 0 {
                    delta += [0, 1]
                }
                if keyS.value > 0 {
                    delta += [0, -1]
                }
                if keyA.value > 0 {
                    delta += [1, 0]
                }
                if keyD.value > 0 {
                    delta += [-1, 0]
                }
                await self?.channel.send(.movement(SIMD3(delta.x, 0, delta.y)))
            }
        }
    }

    private func makeEvent() -> [Event] {
        var allEvents: [Event] = []
        if let controller, let capturedControllerProfile, let move, let strafe, let turn {
            capturedControllerProfile.setStateFromPhysicalInput(controller.physicalInputProfile)
            let movement = SIMD3<Float>(-strafe.value, 0, move.value)
            let rotation = turn.value
            let events = [
                movement != .zero ? Event.movement(movement) : nil,
                rotation != .zero ? Event.rotation(rotation) : nil,
            ].compacted()

            Counters.shared.increment(counter: "Poll: GC")

            allEvents += events
        }
        return allEvents
    }
}

actor MouseMonitor {
    let mouse: GCMouse

    init(mouse: GCMouse) {
        self.mouse = mouse
    }

    func events() -> AsyncStream<SIMD2<Float>> {
        guard let mouseInput = mouse.mouseInput else {
            fatalError("No mouseInput associated with mouse \(mouse).")
        }
        return mouseInput.events()
    }
}

extension GCMouseInput: @unchecked @retroactive Sendable {
}

extension GCMouseInput {
    func events() -> AsyncStream<SIMD2<Float>> {
        AsyncStream { continuation in
            self.mouseMovedHandler = { _, x, y in
                continuation.yield([x, y])
            }
            continuation.onTermination = { @Sendable _ in
                self.mouseMovedHandler = nil
            }
        }
    }
}
