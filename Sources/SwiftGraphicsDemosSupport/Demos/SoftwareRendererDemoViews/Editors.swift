import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

struct ProjectionEditor: View {
    @State
    var type: Projection.Meta

    @Binding
    var projection: Projection

    init(_ projection: Binding<Projection>) {
        type = projection.wrappedValue.meta
        _projection = projection
    }

    var body: some View {
        Picker("Type", selection: $type) {
            ForEach(Projection.Meta.allCases, id: \.self) { type in
                Text(describing: type).tag(type)
            }
        }
        .labelsHidden()
        .onChange(of: type) {
            guard type != projection.meta else {
                return
            }
            switch type {
            case .matrix:
                projection = .matrix(.identity)
            case .perspective:
                projection = .perspective(.init())
            case .orthographic:
                projection = .orthographic(.init(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1))
            }
        }
        switch projection {
        case .matrix:
            //            let projection = Binding {
            //                projection
            //            } set: { newValue in
            //                self.projection = .matrix(newValue)
            //            }
            Text("UNIMPLEMENTED")
        case .perspective(let projection):
            let projection = Binding {
                projection
            } set: { newValue in
                self.projection = .perspective(newValue)
            }
            //                    let fieldOfView = Binding<SwiftUI.Angle>(get: { .degrees(projection.fovy) }, set: { projection.fovy = $0.radians })
            HStack {
                let binding = Binding<SwiftUI.Angle>(radians: projection.verticalAngleOfView.radians)
                TextField("FOVY", value: binding, format: .angle)
                // SliderPopoverButton(value: projection.fovy.degrees, in: 0...180, minimumValueLabel: { Image(systemName: "field.of.view.wide") }, maximumValueLabel: { Image(systemName: "field.of.view.ultrawide") })
            }
            TextField("Clipping Distance", value: projection.zClip, format: ClosedRangeFormatStyle(substyle: .number))
        case .orthographic(let projection):
            let projection = Binding {
                projection
            } set: { newValue in
                self.projection = .orthographic(newValue)
            }
            TextField("Left", value: projection.left, format: .number)
            TextField("Right", value: projection.right, format: .number)
            TextField("Bottom", value: projection.bottom, format: .number)
            TextField("Top", value: projection.top, format: .number)
            TextField("Near", value: projection.near, format: .number)
            TextField("Far", value: projection.far, format: .number)
        }
    }
}

struct TransformEditor: View {
    @Binding
    var transform: Transform

    @State
    var editedTransform: Transform

    @State
    var mode: Transform.Storage.Base

    init(transform: Binding<Transform>) {
        self._transform = transform
        self.editedTransform = transform.wrappedValue
        self.mode = transform.wrappedValue.storage.base
    }

    var body: some View {
        Group {
            Picker("Mode", selection: $mode) {
                Text("Matrix").tag(Transform.Storage.Base.matrix)
                Text("SRT").tag(Transform.Storage.Base.srt)
            }
            switch editedTransform.storage {
            case .matrix:
                MatrixEditor(matrix: $editedTransform.matrix)
            case .srt:
                SRTEditor(srt: $editedTransform.srt)
            }
        }
        .onChange(of: mode) {
            self.editedTransform = transform.converted(to: mode)
        }
        .onChange(of: transform) {
            self.editedTransform = transform.converted(to: mode)
        }
    }
}

extension Transform {
    func converted(to base: Transform.Storage.Base) -> Transform {
        switch base {
        case .matrix:
            Transform(matrix)
        case .srt:
            Transform(srt)
        }
    }
}
extension Transform.Storage {
    enum Base {
        case matrix
        case srt
    }

    var base: Base {
        switch self {
        case .matrix:
            .matrix
        case .srt:
            .srt
        }
    }

}

// MARK: -

struct SRTEditor: View {
    @Binding
    var srt: SRT

    var body: some View {
        Section("Scale") {
            VectorEditor(vector: $srt.scale)
        }
        Section("Rotation") {
            RotationEditor(rotation: $srt.rotation)
        }
        Section("Translation") {
            VectorEditor(vector: $srt.translation)
        }
    }
}

// MARK: -

struct MatrixEditor: View {
    enum Matrix {
        case float4x4(simd_float4x4)
        case float3x3(simd_float3x3)
    }

    @Binding
    var matrix: Matrix

    init(matrix: Binding<Matrix>) {
        self._matrix = matrix
    }

    var body: some View {
        switch matrix {
        case .float4x4(let float4x4):
            Grid {
                GridRow {
                    TextField("", value: .constant(float4x4[0][0]), format: .number)
                    TextField("", value: .constant(float4x4[1][0]), format: .number)
                    TextField("", value: .constant(float4x4[2][0]), format: .number)
                    TextField("", value: .constant(float4x4[3][0]), format: .number)
                }
                GridRow {
                    TextField("", value: .constant(float4x4[0][1]), format: .number)
                    TextField("", value: .constant(float4x4[1][1]), format: .number)
                    TextField("", value: .constant(float4x4[2][1]), format: .number)
                    TextField("", value: .constant(float4x4[3][1]), format: .number)
                }
                GridRow {
                    TextField("", value: .constant(float4x4[0][2]), format: .number)
                    TextField("", value: .constant(float4x4[1][2]), format: .number)
                    TextField("", value: .constant(float4x4[2][2]), format: .number)
                    TextField("", value: .constant(float4x4[3][2]), format: .number)
                }
                GridRow {
                    TextField("", value: .constant(float4x4[0][3]), format: .number)
                    TextField("", value: .constant(float4x4[1][3]), format: .number)
                    TextField("", value: .constant(float4x4[2][3]), format: .number)
                    TextField("", value: .constant(float4x4[3][3]), format: .number)
                }
            }
        case .float3x3(let matrix):
            Grid {
                GridRow {
                    TextField("", value: .constant(matrix[0][0]), format: .number)
                    TextField("", value: .constant(matrix[1][0]), format: .number)
                    TextField("", value: .constant(matrix[2][0]), format: .number)
                }
                GridRow {
                    TextField("", value: .constant(matrix[0][1]), format: .number)
                    TextField("", value: .constant(matrix[1][1]), format: .number)
                    TextField("", value: .constant(matrix[2][1]), format: .number)
                }
                GridRow {
                    TextField("", value: .constant(matrix[0][2]), format: .number)
                    TextField("", value: .constant(matrix[1][2]), format: .number)
                    TextField("", value: .constant(matrix[2][2]), format: .number)
                }
            }
        }
    }
}

extension MatrixEditor {
    init(matrix binding: Binding<simd_float4x4>) {
        self.init(matrix: Binding<Matrix> {
            return .float4x4(binding.wrappedValue)
        }
                  set: { newValue in
            guard case let .float4x4(matrix) = newValue else {
                fatalError()
            }
            binding.wrappedValue = matrix
        }
        )
    }

    init(matrix binding: Binding<simd_float3x3>) {
        self.init(matrix: Binding<Matrix> {
            return .float3x3(binding.wrappedValue)
        }
          set: { newValue in
            guard case let .float3x3(matrix) = newValue else {
                fatalError()
            }
            binding.wrappedValue = matrix
        }
        )
    }
}

// MARk: -

struct RotationEditor: View {
    @Binding
    var rotation: Rotation

    @State
    var mode: Rotation.Storage.Base

    @State
    var editedRotation: Rotation

    init(rotation: Binding<Rotation>) {
        self._rotation = rotation
        self.mode = rotation.wrappedValue.storage.base
        self.editedRotation = rotation.wrappedValue
    }

    var body: some View {
        Group {
            Picker("Mode", selection: $mode) {
                Text("Quaternion").tag(Rotation.Storage.Base.quaternion)
                Text("Roll Pitch Yaw").tag(Rotation.Storage.Base.rollPitchYaw)
            }

            switch editedRotation.storage {
            case .quaternion:
                QuaternionEditor(quaternion: $editedRotation.quaternion)
            case .rollPitchYaw:
                RollPitchYawEditor(rollPitchYaw: $editedRotation.rollPitchYaw)
            }
        }
        .onChange(of: mode) {
            self.editedRotation = rotation.converted(to: mode)
        }
        .onChange(of: rotation) {
            self.editedRotation = rotation.converted(to: mode)
        }
    }
}

extension Rotation {
    func converted(to base: Rotation.Storage.Base) -> Rotation {
        switch base {
        case .quaternion:
            Rotation(quaternion: quaternion)
        case .rollPitchYaw:
            Rotation(rollPitchYaw: rollPitchYaw)
        }
    }
}
extension Rotation.Storage {
    enum Base {
        case quaternion
        case rollPitchYaw
    }

    var base: Base {
        switch self {
        case .quaternion:
            .quaternion
        case .rollPitchYaw:
            .rollPitchYaw
        }
    }

}

// MARK: -

struct RollPitchYawEditor: View {
    @Binding
    var rollPitchYaw: RollPitchYaw

    @State
    var showsMatrix: Bool = false

    @State
    var target: RollPitchYaw.Target = .object

    var body: some View {
        TextField("Roll", value: $rollPitchYaw.roll, format: .angle)
        TextField("Pitch", value: $rollPitchYaw.pitch, format: .angle)
        TextField("Yaw", value: $rollPitchYaw.yaw, format: .angle)
        Toggle("Show Matrix", isOn: $showsMatrix)
        if showsMatrix {
            Picker("Mode", selection: $target) {
                Text("Object").tag(RollPitchYaw.Target.object)
                Text("World").tag(RollPitchYaw.Target.world)
            }
            switch target {
            case .object:
                MatrixEditor(matrix: .constant(rollPitchYaw.matrix3x3))
            case .world:
                MatrixEditor(matrix: .constant(rollPitchYaw.worldMatrix3x3))
            }
        }
    }
}

// MARK: -

struct QuaternionEditor: View {
    @Binding
    var quaternion: simd_quatf

    var body: some View {
        TextField("Real", value: $quaternion.real, format: .number)
        VectorEditor(vector: $quaternion.imag)
    }
}

// MARK: -

struct BallConstraintEditor: View {
    @Binding
    var ballConstraint: BallConstraint

    var body: some View {
        TextField("Radius", value: $ballConstraint.radius, format: .number)
//        TextField("Look AT", value: $ballConstraint.lookAt, format: .vector)
        RollPitchYawEditor(rollPitchYaw: $ballConstraint.rollPitchYaw)

    }
}

// MARK: -

struct VectorEditor: View {
    enum Vector {
        case float2(SIMD2<Float>)
        case float3(SIMD3<Float>)
        case float4(SIMD4<Float>)
    }

    @Binding
    var vector: Vector

    var body: some View {
        switch vector {
        case .float2(let vector):
            let binding = Binding<SIMD2<Float>> {
                return vector
            }
            set: {
                self.vector = .float2($0)
            }
            TextField("x", value: binding.x, format: .number)
            TextField("y", value: binding.y, format: .number)
        case .float3(let vector):
            let binding = Binding<SIMD3<Float>> {
                return vector
            }
            set: {
                self.vector = .float3($0)
            }
            VStack {
                TextField("x", value: binding.x, format: .number)
                TextField("y", value: binding.y, format: .number)
                TextField("z", value: binding.z, format: .number)
            }
        case .float4(let vector):
            let binding = Binding<SIMD4<Float>> {
                return vector
            }
            set: {
                self.vector = .float4($0)
            }
            TextField("x", value: binding.x, format: .number)
            TextField("y", value: binding.y, format: .number)
            TextField("z", value: binding.z, format: .number)
            TextField("w", value: binding.w, format: .number)
        }
    }
}

extension VectorEditor {
    init(vector: Binding<SIMD2<Float>>) {
        let binding = Binding<Vector> {
            .float2(vector.wrappedValue)
        }
        set: {
            guard case let .float2(value) = $0 else {
                fatalError()
            }
            vector.wrappedValue = value
        }
        self.init(vector: binding)
    }
    init(vector: Binding<SIMD3<Float>>) {
        let binding = Binding<Vector> {
            .float3(vector.wrappedValue)
        }
        set: {
            guard case let .float3(value) = $0 else {
                fatalError()
            }
            vector.wrappedValue = value
        }
        self.init(vector: binding)
    }
    init(vector: Binding<SIMD4<Float>>) {
        let binding = Binding<Vector> {
            .float4(vector.wrappedValue)
        }
        set: {
            guard case let .float4(value) = $0 else {
                fatalError()
            }
            vector.wrappedValue = value
        }
        self.init(vector: binding)
    }
}
