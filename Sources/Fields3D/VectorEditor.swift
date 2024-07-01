import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct VectorEditor: View {
    enum Vector {
        case float2(SIMD2<Float>)
        case float3(SIMD3<Float>)
        case float4(SIMD4<Float>)
    }

    @Binding
    var vector: Vector

    public var body: some View {
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

public extension VectorEditor {
    init(_ vector: Binding<SIMD2<Float>>) {
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
    init(_ vector: Binding<SIMD3<Float>>) {
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
    init(_ vector: Binding<SIMD4<Float>>) {
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

#Preview {
    @Previewable @State var vector = SIMD3<Float>.zero
    Form {
        VectorEditor($vector)
    }
}
