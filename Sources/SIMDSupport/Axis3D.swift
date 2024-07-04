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

    // TODO: MOVE
    public var color: Color {
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
