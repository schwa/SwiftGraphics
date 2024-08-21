import simd
import SIMDSupport
import SwiftUI

public struct CameraConeController: ViewModifier {
    private var cameraConeConstraint: CameraConeConstraint

    @Binding
    var transform: Transform

    @State
    private var angle: Angle = .zero
    @State
    private var height: Double = .zero

    public init(cameraCone: CameraCone, transform: Binding<Transform>) {
        self.cameraConeConstraint = .init(cameraCone: cameraCone)
        self._transform = transform
    }

    public func body(content: Content) -> some View {
        content
            .draggableParameter($height, axis: .vertical, range: 0...1, scale: 0.01, behavior: .clamping)
        #if os(macOS)
            .draggableParameter($angle.degrees, axis: .horizontal, range: 0...360, scale: 0.1, behavior: .wrapping)
        #else
            .draggableParameter($angle.degrees, axis: .horizontal, range: 0...360, scale: -0.25, behavior: .wrapping)
        #endif
            .onChange(of: cameraConeConstraint, initial: true) {
                transform = .init(cameraConeConstraint.transform(angle: angle, height: height))
            }
            .onChange(of: angle, initial: true) {
                transform = .init(cameraConeConstraint.transform(angle: angle, height: height))
            }
            .onChange(of: height, initial: true) {
                transform = .init(cameraConeConstraint.transform(angle: angle, height: height))
            }
    }
}

// MARK: -

public struct CameraConeConstraint: Equatable {
    public var cameraCone: CameraCone
    public var lookAt: SIMD3<Float>

    public init(cameraCone: CameraCone, lookAt: SIMD3<Float> = .zero) {
        self.cameraCone = cameraCone
        self.lookAt = lookAt
    }

    func transform(angle: Angle, height: Double) -> simd_float4x4 {
        let position = cameraCone.position(h: Float(height), angle: angle)

        return look(at: lookAt, from: position, up: [0, 1, 0])
    }
}

// MARK: -

public struct CameraCone: Equatable {
    public var apex: SIMD3<Float>
    public var axis: SIMD3<Float>
    public var h1: Float
    public var r1: Float
    public var r2: Float
    public var h2: Float

    public init(apex: SIMD3<Float>, axis: SIMD3<Float>, h1: Float, r1: Float, r2: Float, h2: Float) {
        self.apex = apex
        self.axis = axis
        self.h1 = h1
        self.r1 = r1
        self.r2 = r2
        self.h2 = h2
    }
}

public extension CameraCone {
    func position(h: Float, angle: Angle) -> SIMD3<Float> {
        // Ensure h is between 0 and 1
        let clampedH = max(0, min(1, h))

        // Calculate the radius at h2 h
        let radius = r1 + (r2 - r1) * clampedH

        // Calculate the center point at h2 h
        let center = apex + axis * (h1 + h2 * clampedH)

        // Calculate the point on the circle at the given angle
        let angleInRadians = Float(angle.radians)
        let x = radius * cos(angleInRadians)
        let z = radius * sin(angleInRadians)

        // Create a coordinate system where Y is along the axis
        let up = axis
        let right = SIMD3<Float>(up.z, up.x, up.y) // Arbitrary perpendicular vector
        let forward = simd_cross(up, right)

        // Transform the point to the cone's coordinate system
        return center + right * x + forward * z
    }
}
