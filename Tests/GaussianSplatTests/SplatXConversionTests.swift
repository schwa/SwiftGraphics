import Testing
import GaussianSplatSupport
import GaussianSplatShaders
import ApproximateEquality

@Test(arguments: [
    (
        SplatB(position: [0, 0, 0], scale: [1, 1, 1], color: [255, 255, 255, 255], rotation: [128, 128, 128, 255]),
        SplatX(position: [0, 0, 0], u1: [3.7539063, 0.0], u2: [0.0, 3.7539063], u3: [0.0, 4.0], color: [255, 255, 255, 255]),
        0.000_000_1
    ),
    (
        SplatB(position: [5.1992097, 14.8973675, -1.0287564], scale: [0.3719001, 0.41435486, 0.22165838], color: [22, 39, 53, 255], rotation: [67, 96, 211, 59]),
        SplatX(position: [5.1992097, 14.8973675, -1.0287564], u1: [0.6044922, -0.14904785], u2: [0.05557251, 0.25170898], u3: [-0.0061683655, 0.58154297], color: [22, 39, 53, 255]),
        0.001
    ),
    (
        SplatB(position: [0, 0, 0], scale: [1, 0.5, 0.25], color: [255, 0, 255, 255], rotation: [128, 128, 128, 255]),
        SplatX(position: [0.0, 0.0, 0.0], u1: [3.7539063, 0.0], u2: [0.0, 0.93847656], u3: [0.0, 0.25], color: [255, 0, 255, 255]),
        0.0001
    ),
])
func testSplatXConversion(splatB: SplatB, splatX: SplatX, absoluteTolerance: Double) {
    #expect(SplatX(splatB).isApproximatelyEqual(to: splatX, absoluteTolerance: absoluteTolerance))
}

extension SplatX: @retroactive ApproximateEquality {
    public func isApproximatelyEqual(to other: Self, absoluteTolerance: Double.Magnitude) -> Bool {
        return position.isApproximatelyEqual(to: other.position, absoluteTolerance: Float(absoluteTolerance)) &&
            u1.isApproximatelyEqual(to: other.u1, absoluteTolerance: Float16(absoluteTolerance)) &&
            u2.isApproximatelyEqual(to: other.u2, absoluteTolerance: Float16(absoluteTolerance)) &&
            u3.isApproximatelyEqual(to: other.u3, absoluteTolerance: Float16(absoluteTolerance)) &&
            color == other.color
    }
}
