import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct MatrixEditor: View {
    enum Matrix {
        case float4x4(simd_float4x4)
        case float3x3(simd_float3x3)
    }

    @Binding
    var matrix: Matrix

    public var body: some View {
        Group {
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
        .labelsHidden()
    }
}

public extension MatrixEditor {
    init(_ binding: Binding<simd_float4x4>) {
        self.init(matrix: Binding<Matrix> {
            .float4x4(binding.wrappedValue)
        }
                  set: { newValue in
            guard case let .float4x4(matrix) = newValue else {
                fatalError()
            }
            binding.wrappedValue = matrix
        }
        )
    }

    init(_ binding: Binding<simd_float3x3>) {
        self.init(matrix: Binding<Matrix> {
            .float3x3(binding.wrappedValue)
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

// MARK: -

public struct MatrixView <Matrix>: View where Matrix: FormattableMatrix, Matrix.Scalar == Float {
    var matrix: Matrix

    public init(_ matrix: Matrix) {
        self.matrix = matrix
    }

    public var body: some View {
        Group {
            Grid {
                ForEach(0..<matrix.columnCount, id: \.self) { column in
                    GridRow {
                        ForEach(0..<matrix.rowCount, id: \.self) { row in
                            let value = matrix[column, row]
                            let color: Color = value == 0 ? .primary : (value < 0 ? .red : .green)
                            Text(value, format: .number)
                            .lineLimit(1)
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .foregroundStyle(color)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var matrix = simd_float4x4()
    Form {
        MatrixEditor($matrix)
        MatrixView(matrix)
    }
}
