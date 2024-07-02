import Everything
import Fields3D
import MetalKit
import MetalSupport
import Observation
import RenderKit
import simd
import SIMDSupport
import SwiftFields
import SwiftGraphicsSupport
import SwiftUI
import UniformTypeIdentifiers
import GaussianSplatSupport

// swiftlint:disable force_try

public struct SingleSplatView: View {
    @State
    private var cameraTransform: Transform = .translation([0, 0, 10])

    @State
    private var cameraProjection: Projection = .perspective(.init())

    @State
    private var ballConstraint = BallConstraint(radius: 5)

    @State
    private var modelTransform: Transform = .init(scale: [1, 1, 1])

    @State
    private var device: MTLDevice

    @State
    private var debugMode: Bool = false

    @State
    private var splats: MTLBuffer

    @State
    private var splatIndices: MTLBuffer

    @State
    private var splat: SplatD

    public init() {
        let device = MTLCreateSystemDefaultDevice()!

        assert(MemoryLayout<SplatC>.size == 26)

        let splat = SplatD(position: [0, 0, 0], scale: [0.1, 0.1, 0.1], color: [1, 0, 0, 1], rotation: .init(angle: .zero, axis: [0, 0, 0]))

        let splats = try! device.makeBuffer(bytesOf: [splat], options: .storageModeShared)
        let splatIndices = try! device.makeBuffer(bytesOf: [UInt32.zero], options: .storageModeShared)

        self.device = device
        self.splat = splat
        self.splats = splats
        self.splatIndices = splatIndices
    }

    public var body: some View {
        RenderView(device: device, passes: passes)
//            .ballRotation($ballConstraint.rollPitchYaw, updatesPitch: true, updatesYaw: true)
            .onChange(of: ballConstraint.transform, initial: true) {
                cameraTransform = ballConstraint.transform
                print(cameraTransform)
            }
//            .overlay(alignment: .topLeading) {
//                CameraRotationWidgetView(ballConstraint: $ballConstraint)
//                    .frame(width: 120, height: 120)
//            }
            .onChange(of: splat) {
                let splats = try! device.makeBuffer(bytesOf: [SplatC(splat)], options: .storageModeShared)
                self.splats = splats
            }
            .inspector(isPresented: .constant(true)) {
                Form {
                    Section("Camera") {
                        HStack {
                            TextField("Roll", value: $cameraTransform.rotation.rollPitchYaw.roll.degrees, format: .number)
                            TextField("Pitch", value: $cameraTransform.rotation.rollPitchYaw.pitch.degrees, format: .number)
                            TextField("Yaw", value: $cameraTransform.rotation.rollPitchYaw.yaw.degrees, format: .number)
                        }
                        .labelsHidden()
                    }
                    Section("Position") {
                        HStack {
                            TextField("X", value: $splat.position.x, format: .number)
                            TextField("Y", value: $splat.position.y, format: .number)
                            TextField("Z", value: $splat.position.z, format: .number)
                        }
                        .labelsHidden()
                    }
                    Section("Scale") {
                        HStack {
                            TextField("X", value: $splat.scale.x, format: .number)
                            TextField("Y", value: $splat.scale.y, format: .number)
                            TextField("Z", value: $splat.scale.z, format: .number)
                        }
                        .labelsHidden()
                    }
                    Section("Color") {
                        HStack {
                            TextField("R", value: $splat.color.x, format: .number)
                            TextField("G", value: $splat.color.y, format: .number)
                            TextField("B", value: $splat.color.z, format: .number)
                            TextField("A", value: $splat.color.w, format: .number)
                        }
                        .labelsHidden()
                    }
                    Section("Rotation") {
                        RotationEditor($splat.rotation)
                    }
                    Section("SplatB") {
                        Text("\(SplatB(splat))")
                    }
                    Section("SplatC") {
                        Text("\(SplatC(splat))")
                    }

                    //                Section("COV_A") {
                    //                    HStack {
                    //                        TextField("0", value: $splat.cov_a.x, format: .number)
                    //                        TextField("1", value: $splat.cov_a.y, format: .number)
                    //                        TextField("2", value: $splat.cov_a.z, format: .number)
                    //                    }
                    //                    .labelsHidden()
                    //                }
                    //                Section("COV_B") {
                    //                    HStack {
                    //                        TextField("0", value: $splat.cov_b.x, format: .number)
                    //                        TextField("1", value: $splat.cov_b.y, format: .number)
                    //                        TextField("2", value: $splat.cov_b.z, format: .number)
                    //                    }
                    //                    .labelsHidden()
                    //                }
                }
                Toggle(isOn: $debugMode) {
                    Text("Debug")
                }
            }
    }

    var passes: [any PassProtocol] {
        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            cameraTransform: cameraTransform,
            cameraProjection: cameraProjection,
            modelTransform: modelTransform,
            splatCount: 1,
            splats: Box(splats),
            splatIndices: Box(splatIndices),
            debugMode: debugMode
        )
        return [
            gaussianSplatRenderPass
        ]
    }
}
