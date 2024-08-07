import simd
import SIMDSupport
import SwiftUI

public struct CameraConeController: ViewModifier {
    @State
    private var cameraConeConstraint: CameraConeConstraint

    @Binding var transform: Transform

    public init(cameraCone: CameraCone, transform: Binding<Transform>) {
        self.cameraConeConstraint = .init(cameraCone: cameraCone)
        self._transform = transform
    }

    public func body(content: Content) -> some View {
        content
        .draggableParameter($cameraConeConstraint.height, axis: .vertical, range: 0...1, scale: 0.01, behavior: .clamping)
        .draggableParameter($cameraConeConstraint.angle.degrees, axis: .horizontal, range: 0...360, scale: 0.1, behavior: .wrapping)
        .onChange(of: cameraConeConstraint.position, initial: true) {
            let cameraPosition = cameraConeConstraint.position
            transform.matrix = look(at: cameraConeConstraint.lookAt, from: cameraPosition, up: [0, 1, 0])
        }
    }
}

// MARK: -

public struct CameraConeConstraint: Equatable {
    public var cameraCone: CameraCone
    public var lookAt: SIMD3<Float>
    public var position: SIMD3<Float> {
        cameraCone.position(h: Float(height), angle: angle)
    }

    public var angle: Angle
    public var height: Double

    public init(cameraCone: CameraCone, lookAt: SIMD3<Float> = .zero, angle: Angle = .zero, height: Double = .zero) {
        self.cameraCone = cameraCone
        self.lookAt = lookAt
        self.angle = angle
        self.height = height
    }
}

// MARK: -

public struct CameraCone: Equatable {
    public var apex: SIMD3<Float>
    public var axis: SIMD3<Float>
    public var apexToTopBase: Float
    public var topBaseRadius: Float
    public var bottomBaseRadius: Float
    public var height: Float

    public init(apex: SIMD3<Float>, axis: SIMD3<Float>, apexToTopBase: Float, topBaseRadius: Float, bottomBaseRadius: Float, height: Float) {
        self.apex = apex
        self.axis = axis
        self.apexToTopBase = apexToTopBase
        self.topBaseRadius = topBaseRadius
        self.bottomBaseRadius = bottomBaseRadius
        self.height = height
    }
}

public extension CameraCone {
    func position(h: Float, angle: Angle) -> SIMD3<Float> {
        // Ensure h is between 0 and 1
        let clampedH = max(0, min(1, h))

        // Calculate the radius at height h
        let radius = topBaseRadius + (bottomBaseRadius - topBaseRadius) * clampedH

        // Calculate the center point at height h
        let center = apex + axis * (apexToTopBase + height * clampedH)

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
