import BaseSupport
import Foundation
@preconcurrency import GameController
import SwiftUI
import SwiftUISupport

// swiftlint:disable force_try

struct GameControllerWidget: View {
    @State
    private var model = GameControllerWidgetModel()

    var body: some View {
        HStack {
            //            Image(systemName: "gamecontroller").symbolEffect(.pulse.byLayer)
            //                .symbolRenderingMode(.palette)
            //                .foregroundStyle(.red, .green, .blue)
            //                .background(.white)
            Menu {
                if model.scanning == false {
                    Button("Start Scanning") {
                        model.startDiscovery()
                    }
                }
                else {
                    Button("Stop Scanning") {
                        model.stopDiscovery()
                    }
                }
                #if os(iOS)
                Divider()
                if model.virtualController != nil {
                    Button("Disable Touch Controller") {
                        model.virtualController?.disconnect()
                        model.virtualController = nil
                    }
                }
                else {
                    Button("Enable Touch Controller") {
                        Task {
                            let configuration = GCVirtualController.Configuration()
                            configuration.elements = [
                                GCInputLeftThumbstick, GCInputRightThumbstick, GCInputLeftShoulder, GCInputRightShoulder,
                                //                        GCInputButtonA,
                                //                        GCInputButtonB,
                                //                        GCInputButtonX,
                                //                        GCInputButtonY,
                                // GCInputDirectionPad,
                                //                        GCInputLeftTrigger,
                                //                        GCInputRightTrigger
                            ]
                            let virtualController = GCVirtualController(configuration: configuration)
                            try! await virtualController.connect()
                            model.virtualController = virtualController
                        }
                    }
                }
                #endif
                if !model.devices.isEmpty {
                    Divider()
                    ForEach(Array(model.devices), id: \.self) { box in
                        Label {
                            let isCurrent = (box.content as? GCController) === GCController.current
                            Text("\(box.content.productCategory) / \(box.content.vendorName ?? "unknown controller")") + (isCurrent ? Text(" (current)") : Text(""))
                        } icon: {
                            box.content.sfSymbolName.map { Image(systemName: $0) } ?? Image(systemName: "questionmark.square.dashed")
                        }
                    }
                }
                Button("More Info…") {
                }

                //                Button(action: {}, label: {
                //                    Image(systemName: "gamecontroller").symbolEffect(.pulse.byLayer)
                //                })
            }
            label: {
                Label(
                    title: { Text("Game Controller") },
                    icon: {
                        if model.devices.isEmpty {
                            Image(systemName: "gamecontroller")
                        }
                        else {
                            Image(systemName: "gamecontroller.fill")
                        }
                    }
                )
                .labelStyle(.iconOnly)
            }
            .fixedSize()
            .backgroundStyle(Color.yellow)
        }
    }
}

@Observable
@MainActor
class GameControllerWidgetModel: @unchecked Sendable {
    var scanning = false

    typealias DeviceBox = Box<any GCDevice>

    var devices: Set<DeviceBox> = []

    #if os(iOS)
    var virtualController: GCVirtualController?
    // Temporary workaround for FB12509166
    #endif

    @ObservationIgnored
    var monitorTask: Task<Void, Never>?

    init() {
        InlineNotificationsManager.shared.post(.init(title: "GameControllerWidgetModel.init()"))

        devices.formUnion(GCController.controllers().map(DeviceBox.init))

        InlineNotificationsManager.shared.post(.init(title: "Devices: \(devices)"))


        monitorTask = Task { [weak self] in
            await withDiscardingTaskGroup { [weak self] group in
                let notificationCenter = NotificationCenter.default
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCControllerDidConnect) {
                        if let device = notification.object as? GCDevice {
                            InlineNotificationsManager.shared.post(.init(title: "Got device", message: "\(device)"))
                            self?.addDevice(device)
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCControllerDidDisconnect) {
                        if let device = notification.object as? GCDevice {
                            self?.removeDevice(device)
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCKeyboardDidConnect) {
                        if let device = notification.object as? GCDevice {
                            InlineNotificationsManager.shared.post(.init(title: "Got device", message: "\(device)"))
                            self?.addDevice(device)
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCKeyboardDidDisconnect) {
                        if let device = notification.object as? GCDevice {
                            self?.removeDevice(device)
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCMouseDidConnect) {
                        if let device = notification.object as? GCDevice {
                            InlineNotificationsManager.shared.post(.init(title: "Got device", message: "\(device)"))
                            self?.addDevice(device)
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCMouseDidDisconnect) {
                        if let device = notification.object as? GCDevice {
                            self?.removeDevice(device)
                        }
                    }
                }
            }
        }
        startDiscovery()
    }

    deinit {
        monitorTask?.cancel()
    }

    nonisolated
    func addDevice(_ device: any GCDevice) {
        MainActor.runTask {
            let box = DeviceBox(device)
            self.devices.insert(box)
        }
    }

    nonisolated
    func removeDevice(_ device: any GCDevice) {
        MainActor.runTask {
            let box = DeviceBox(device)
            self.devices.remove(box)
        }
    }

    func startDiscovery() {
        guard scanning == false else {
            return
        }
        scanning = true
        GCController.startWirelessControllerDiscovery { [weak self] in
            self?.scanning = false
        }
    }

    func stopDiscovery() {
        GCController.stopWirelessControllerDiscovery()
        scanning = false
    }
}

extension GCDevice {
    var sfSymbolName: String? {
        switch self {
        case _ as GCController:
            "gamecontroller"
        case _ as GCKeyboard:
            "keyboard"
        case _ as GCMouse:
            "mouse"
        default:
            nil
        }
    }
}

enum GCElementKey: String, CaseIterable {
    case buttonA = "Button A"
    case buttonB = "Button B"
    case buttonMenu = "Button Menu"
    case buttonX = "Button X"
    case buttonY = "Button Y"
    case directionPad = "Direction Pad"
    case directionPadDown = "Direction Pad Down"
    case directionPadLeft = "Direction Pad Left"
    case directionPadRight = "Direction Pad Right"
    case directionPadUp = "Direction Pad Up"
    case directionPadXAxis = "Direction Pad X Axis"
    case directionPadYAxis = "Direction Pad Y Axis"
    case leftShoulder = "Left Shoulder"
    case leftThumbstick = "Left Thumbstick"
    case leftThumbstickDown = "Left Thumbstick Down"
    case leftThumbstickLeft = "Left Thumbstick Left"
    case leftThumbstickRight = "Left Thumbstick Right"
    case leftThumbstickUp = "Left Thumbstick Up"
    case leftThumbstickXAxis = "Left Thumbstick X Axis"
    case leftThumbstickYAxis = "Left Thumbstick Y Axis"
    case leftTrigger = "Left Trigger"
    case rightShoulder = "Right Shoulder"
    case rightThumbstick = "Right Thumbstick"
    case rightThumbstickDown = "Right Thumbstick Down"
    case rightThumbstickLeft = "Right Thumbstick Left"
    case rightThumbstickRight = "Right Thumbstick Right"
    case rightThumbstickUp = "Right Thumbstick Up"
    case rightThumbstickXAxis = "Right Thumbstick X Axis"
    case rightThumbstickYAxis = "Right Thumbstick Y Axis"
    case rightTrigger = "Right Trigger"
}
