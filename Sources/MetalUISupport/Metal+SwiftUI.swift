@preconcurrency import Metal
import SwiftUI

struct MTLDeviceKey: EnvironmentKey {
    static let defaultValue: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("No default metal device found.")
        }
        return device
    }()
}

public extension EnvironmentValues {
    var metalDevice: MTLDevice {
        get {
            self[MTLDeviceKey.self]
        }
        set {
            self[MTLDeviceKey.self] = newValue
        }
    }
}

struct MTLDeviceModifier: ViewModifier {
    let value: MTLDevice
    func body(content: Content) -> some View {
        content.environment(\.metalDevice, value)
    }
}

public extension View {
    func metalDevice(_ value: MTLDevice) -> some View {
        modifier(MTLDeviceModifier(value: value))
    }

    func metalDevice() -> some View {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Well that's just not much fun is it?")
        }
        return modifier(MTLDeviceModifier(value: device))
    }
}
