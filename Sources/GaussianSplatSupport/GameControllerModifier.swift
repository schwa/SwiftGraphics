import GameController
import Observation
import simd
import SIMDSupport
import SwiftUI

struct GameControllerModifier: ViewModifier {
    @State
    private var viewModel = ViewModel.shared

    @Binding
    var cameraMatrix: simd_float4x4

    init(cameraMatrix: Binding<simd_float4x4>) {
        self._cameraMatrix = cameraMatrix
    }

    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            content
                .onChange(of: timeline.date) {
                    // adjust camera matrix by controller input
                    let movement = viewModel.movement
                    let translation = simd_make_float3(movement.x, 0, movement.y * -1) * 0.1
                    cameraMatrix = cameraMatrix * simd_float4x4(translate: translation)

                    // adjust camera matrix by controller input
                    let rotation = viewModel.rotation
                    let yaw = Angle(radians: Double(rotation.x) * .pi) * 0.1
                    let pitch = Angle(radians: Double(rotation.y) * .pi) * 0.05
                    let quaternion = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: pitch, axis: [1, 0, 0])
                    cameraMatrix = cameraMatrix * simd_float4x4(quaternion)
                }
        }
        .overlay(alignment: .bottom) {
            VStack {
                Text("Game Controller")
                Text("Movement: \(viewModel.movement)")
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding()
        }
    }
}

extension GameControllerModifier {
    @Observable
    @MainActor
    class ViewModel {
        static let shared = ViewModel()

        var controller: GCController?

        var observationTask: Any?

        var movement: simd_float2 = .zero
        var rotation: simd_float2 = .zero

        init() {
            observationTask = Task {
                Task {
                    for await event in NotificationCenter.default.notifications(named: .GCControllerDidConnect) {
                        guard let controller = event.object as? GCController else {
                            continue
                        }
                        updateController()
                    }
                }
                Task {
                    for await event in NotificationCenter.default.notifications(named: .GCControllerDidDisconnect) {
                        guard let controller = event.object as? GCController else {
                            continue
                        }
                        updateController()
                    }
                }
            }
        }

        func updateController() {
            controller = GCController.current
            controller?.extendedGamepad?.leftThumbstick.yAxis.valueChangedHandler = { [weak self] _, value in
                self?.movement.y = value
            }
            controller?.extendedGamepad?.leftThumbstick.xAxis.valueChangedHandler = { [weak self] _, value in
                self?.movement.x = value
            }
            controller?.extendedGamepad?.rightThumbstick.yAxis.valueChangedHandler = { [weak self] _, value in
                self?.rotation.y = value
            }
            controller?.extendedGamepad?.rightThumbstick.xAxis.valueChangedHandler = { [weak self] _, value in
                self?.rotation.x = value
            }
        }
    }
}
