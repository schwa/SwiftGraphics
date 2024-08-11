import BaseSupport
@preconcurrency import GameController
import os
import SwiftUI

struct GameControllerInspector: View {
    @State
    private var viewModel = GameControllerViewModel()

    var body: some View {
        NavigationStack {
            controllerListView
                .navigationDestination(for: Box<GCDevice>.self) { device in
                    if let controller = device.content as? GCController {
                        detail(for: controller)
                    }
                }
        }
    }

    @ViewBuilder
    var controllerListView: some View {
        List {
            Section("Controllers: \(viewModel.controllers.count)") {
                ForEach(viewModel.controllers, id: \.self) { controller in
                    row(for: controller)
                }
            }
            Section("Devices: \(viewModel.devices.count)") {
                ForEach(Array(viewModel.devices.enumerated()), id: \.0) { _, device in
                    row(for: device)
                }
            }
            if let device = viewModel.currentController {
                Section("Current Controller") {
                    row(for: device)
                }
            }
            if let device = viewModel.coalescedKeyboard {
                Section("Coalesced Keyboard") {
                    row(for: device)
                }
            }
            if let device = viewModel.currentMouse {
                Section("GCMouse.current") {
                    row(for: device)
                }
            }
        }
        if !viewModel.scanning {
            Button("Wireless Scan") {
                Task {
                    await viewModel.startScanning()
                }
            }
        } else {
            ProgressView()
            Button("Stop Scanning") {
                viewModel.stopScanning()
            }
        }
    }

    @ViewBuilder
    func row(for device: GCDevice) -> some View {
        NavigationLink(value: Box(device)) {
            HStack {
                Group {
                    if device is GCController {
                        Image(systemName: "gamecontroller")
                    } else if device is GCKeyboard {
                        Image(systemName: "keyboard")
                    } else if device is GCMouse {
                        Image(systemName: "computermouse")
                    }
                }
                .frame(width: 32)

                VStack(alignment: .leading) {
                    Text("\(device.productCategory)")
                    if let vendorName = device.vendorName {
                        Text("\(vendorName)").font(.caption).opacity(0.5)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func detail(for controller: GCController) -> some View {
        List {
            Image(systemName: "gamecontroller")
            Text("\(controller.productCategory)")
            if let vendorName = controller.vendorName {
                Text("\(vendorName)").font(.caption).opacity(0.5)
            }

            LabeledContent("Current?", value: controller == GCController.current)
            LabeledContent("isAttachedToDevice?", value: controller.isAttachedToDevice)
            LabeledContent("isSnapshot?", value: controller.isSnapshot)
            LabeledContent("playerIndex", value: "\(controller.playerIndex)")
            LabeledContent("input", value: "\(controller.input)")
            if let battery = controller.battery, battery.batteryState != .unknown {
                LabeledContent("Battery Level", value: "\(battery.batteryLevel)")
                LabeledContent("Battery State", value: "\(battery.batteryState)")
            }
            LabeledContent("physicalInputProfile", value: "\(controller.physicalInputProfile)")
            LabeledContent("microGamepad", value: "\(String(describing: controller.microGamepad))")
            LabeledContent("extendedGamepad", value: "\(String(describing: controller.extendedGamepad))")
            LabeledContent("motion", value: "\(String(describing: controller.motion))")
            LabeledContent("light", value: "\(String(describing: controller.light))")
            if let light = controller.light {
                let color = Color(red: Double(light.color.red), green: Double(light.color.green), blue: Double(light.color.blue))
                ColorPicker("?", selection: .constant(color))
            }
            LabeledContent("haptics", value: "\(String(describing: controller.haptics))")
            let profile = controller.physicalInputProfile
            LabeledContent("lastEventTimestamp", value: "\(profile.lastEventTimestamp)")
            LabeledContent("hasRemappedElements", value: "\(profile.hasRemappedElements)")
            Section("Buttons") {
                ForEach(Array(profile.allButtons), id: \.self) { element in
                    row(for: element)
                }
            }
            Section("Axes") {
                ForEach(Array(profile.allAxes), id: \.self) { element in
                    row(for: element)
                }
            }
            Section("DPads") {
                ForEach(Array(profile.allDpads), id: \.self) { element in
                    row(for: element)
                }
            }
            Section("Touchpads") {
                ForEach(Array(profile.allTouchpads), id: \.self) { element in
                    row(for: element)
                }
            }
        }
    }

    @ViewBuilder
    func row(for element: GCControllerElement) -> some View {
        VStack(alignment: .leading) {
            HStack {
                if let sfSymbolsName = element.sfSymbolsName {
                    Image(systemName: sfSymbolsName)
                }
                Text(element.localizedName ?? "<unknown>")
            }
            Text("\(element.aliases.joined(separator: ", "))").font(.caption).opacity(0.5)
        }
    }
}

extension LabeledContent where Label == Text, Content == Text {
    init(_ titleKey: LocalizedStringKey, value: Bool) {
        self.init(titleKey, value: value.formatted())
    }
}

@MainActor
@Observable
class GameControllerViewModel {
    var controllers: [GCController] = []
    var devices: [GCDevice] = []
    var scanning = false
    var currentMouse: GCMouse?
    var coalescedKeyboard: GCKeyboard?
    var currentController: GCController?
    var logger: Logger? = Logger()

    var monitorTask: Task<(), Never>?

    init() {
        startMonitoring()
        update()
    }

    func update() {
        controllers = GCController.controllers()
        currentMouse = GCMouse.current
        coalescedKeyboard = GCKeyboard.coalesced
        currentController = GCController.current
    }

    func startScanning() async {
        scanning = true
        defer {
            scanning = false
        }
        await GCController.startWirelessControllerDiscovery()
        controllers = GCController.controllers()
    }

    func stopScanning() {
        GCController.stopWirelessControllerDiscovery()
    }

    func addDevice(_ device: GCDevice) {
        update()
        guard !devices.contains(where: { $0 === device }) else {
            return
        }
        devices.append(device)
    }

    func removeDevice(_ device: GCDevice) {
        devices.removeAll { $0 === device }
        update()
    }

    func startMonitoring() {
        let logger = logger
        monitorTask = Task { [weak self] in
            await withDiscardingTaskGroup { [weak self] group in
                let notificationCenter = NotificationCenter.default
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCControllerDidConnect) {
                        if let device = notification.object as? GCController {
                            await self?.addDevice(device)
                            logger?.info("Controller connected: \(device)")
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCControllerDidDisconnect) {
                        if let device = notification.object as? GCController {
                            await self?.removeDevice(device)
                            logger?.info("Controller disconnected: \(device)")
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCKeyboardDidConnect) {
                        if let device = notification.object as? GCKeyboard {
                            await self?.addDevice(device)
                            logger?.info("Keyboard connected: \(device)")
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCKeyboardDidDisconnect) {
                        if let device = notification.object as? GCKeyboard {
                            await self?.removeDevice(device)
                            logger?.info("Keyboard disconnected: \(device)")
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCMouseDidConnect) {
                        if let device = notification.object as? GCMouse {
                            await self?.addDevice(device)
                            logger?.info("Mouse connected: \(device)")
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await notification in notificationCenter.notifications(named: .GCMouseDidDisconnect) {
                        if let device = notification.object as? GCMouse {
                            await self?.removeDevice(device)
                            logger?.info("Mouse disconnected: \(device)")
                        }
                    }
                }
                group.addTask { [weak self] in
                    for await _ in notificationCenter.notifications(named: .GCControllerDidBecomeCurrent) {
                        await self?.update()
                    }
                }
                group.addTask { [weak self] in
                    for await _ in notificationCenter.notifications(named: .GCControllerDidStopBeingCurrent) {
                        await self?.update()
                    }
                }
            }
        }
    }
}
