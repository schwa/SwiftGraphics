import simd
import SwiftUI

public enum Axis3D: CaseIterable {
    case x
    case y
    case z

    public var vector: SIMD3<Float> {
        switch self {
        case .x:
            [1, 0, 0]
        case .y:
            [0, 1, 0]
        case .z:
            [0, 0, 1]
        }
    }
}

public extension Axis3D {
    var color: Color {
        switch self {
        case .x:
            .red
        case .y:
            .green
        case .z:
            .blue
        }
    }
}

public extension RollPitchYaw {
    mutating func setAxis(_ vector: SIMD3<Float>) {
        switch vector {
        case [-1, 0, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(0), yaw: .degrees(90))
        case [1, 0, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(0), yaw: .degrees(270))
        case [0, -1, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(90), yaw: .degrees(0))
        case [0, 1, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(270), yaw: .degrees(0))
        case [0, 0, -1]:
            self = .init(roll: .degrees(0), pitch: .degrees(180), yaw: .degrees(0))
        case [0, 0, 1]:
            self = .init(roll: .degrees(0), pitch: .degrees(0), yaw: .degrees(0))
        default:
            break
        }
    }
}
