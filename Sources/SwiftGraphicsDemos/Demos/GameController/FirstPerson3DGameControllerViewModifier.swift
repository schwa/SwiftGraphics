import GameController
import simd
import SIMDSupport
import SwiftUI

struct FirstPerson3DGameControllerViewModifier: ViewModifier {
    @Binding
    var transform: Transform

    @State
    var fpvController: FirstPerson3D

    @State
    var lastUpdate: Date?

    init(transform: Binding<Transform>, controller: GCController? = nil) {
        self._transform = transform
        self.fpvController = FirstPerson3D(controller: controller, transform: transform.wrappedValue.matrix)
    }

    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            content
                .onChange(of: timeline.date) {
                    let now = timeline.date
                    if let lastUpdate = lastUpdate {
                        let deltaTime = now.timeIntervalSince(lastUpdate)
                        fpvController.update(deltaTime: deltaTime)
                    }
                    lastUpdate = lastUpdate
                }
                .onChange(of: fpvController.transform) {
                    transform.matrix = fpvController.transform
                }
        }
    }
}

struct FirstPerson3D {
    var controller: GCController?
    var transform: simd_float4x4
    var lastUpdate: Date?
    var orientation: RollPitchYaw

    var forwardCurve: (Float, TimeInterval) -> Float = { input, deltaTime in
        let speed: Float = 2.0 // forwardSpeed
        return pow(input, 2) * (input < 0 ? -1 : 1) * speed * Float(deltaTime)
    }
    var strafeCurve: (Float, TimeInterval) -> Float = { input, deltaTime in
        let speed: Float = 1.5 // strafeSpeed
        return input * speed * Float(deltaTime)
    }
    var yawCurve: (Float, TimeInterval) -> Float = { input, deltaTime in
        let speed: Float = 1.5 // rotationSpeed
        return pow(input, 3) * speed * Float(deltaTime)
    }
    var rollCurve: (Float, TimeInterval) -> Float = { input, deltaTime in
        let speed: Float = 1.0 // rollSpeed
        return input * speed * Float(deltaTime)
    }
    var verticalCurve: (Float, TimeInterval) -> Float = { input, deltaTime in
        input * Float(deltaTime)
    }

    init(controller: GCController? = nil, transform: simd_float4x4) {
        self.controller = controller
        self.transform = transform
        self.orientation = RollPitchYaw()
    }

    mutating func update(deltaTime: TimeInterval) {
        guard let controller = controller ?? GCController.current, let profile = controller.capture().extendedGamepad else {
            return
        }

        // Movement
        var movement = SIMD3<Float>(0, 0, 0)
        if let xAxis = profile.dpads[GCInputLeftThumbstick]?.xAxis.value {
            movement.x = strafeCurve(Float(xAxis), deltaTime)
        }
        if let yAxis = profile.dpads[GCInputLeftThumbstick]?.yAxis.value {
            movement.z = -forwardCurve(Float(yAxis), deltaTime)
        }

        // Vertical movement
        if let dpad = profile.dpads[GCInputDirectionPad] {
            if dpad.up.isPressed {
                movement.y += verticalCurve(1, deltaTime)
            }
            if dpad.down.isPressed {
                movement.y -= verticalCurve(1, deltaTime)
            }
        }

        // Rotation
        var rotation = RollPitchYaw()
        if let rightXAxis = profile.dpads[GCInputRightThumbstick]?.xAxis.value {
            rotation.yaw = -Angle(radians: Double(yawCurve(Float(rightXAxis), deltaTime)))
        }
        if let rightYAxis = profile.dpads[GCInputRightThumbstick]?.yAxis.value {
            rotation.pitch = Angle(radians: Double(-yawCurve(Float(rightYAxis), deltaTime)))
        }

        // Roll - Corrected version
        var rollChange: Float = 0
        if let leftShoulder = profile.buttons[GCInputLeftShoulder] {
            rollChange -= rollCurve(leftShoulder.value, deltaTime)
        }
        if let rightShoulder = profile.buttons[GCInputRightShoulder] {
            rollChange += rollCurve(rightShoulder.value, deltaTime)
        }
        rotation.roll = Angle(radians: Double(rollChange))

        apply(movement: movement, rotation: rotation)
    }

    private mutating func apply(movement: SIMD3<Float>, rotation: RollPitchYaw) {
        // Apply rotation
        orientation.yaw += rotation.yaw
        orientation.pitch += rotation.pitch
        orientation.roll += rotation.roll

        // Clamp pitch to avoid flipping
        orientation.pitch = Angle(radians: max(min(orientation.pitch.radians, .pi / 2), -.pi / 2))

        // Create rotation matrix
        let rotationMatrix = orientation.matrix4x4

        // Combine the new rotation with the existing translation
        transform.columns.0 = rotationMatrix.columns.0
        transform.columns.1 = rotationMatrix.columns.1
        transform.columns.2 = rotationMatrix.columns.2

        // Apply movement in the direction we're facing
        let worldMovement = rotationMatrix * SIMD4<Float>(movement, 0)
        transform.columns.3 += worldMovement
    }
}
