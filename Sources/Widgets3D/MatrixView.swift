import SwiftUI
import simd
import SwiftFormats

public struct MatrixView <Matrix>: View where Matrix: FormattableMatrix, Matrix.Scalar: BinaryFloatingPoint {
    var matrix: Matrix

    public init(_ matrix: Matrix) {
        self.matrix = matrix
    }

    public var body: some View {
        Group {
            Grid {
                ForEach(0..<matrix.rowCount, id: \.self) { row in
                    GridRow {
                        ForEach(0..<matrix.columnCount, id: \.self) { column in
                            let value = matrix[column, row]
                            Text("\(value)")
                                .lineLimit(1)
                                .monospacedDigit()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundStyle(color(for: value))
                        }
                    }
                }
            }
        }
        .contextMenu {
            Button("Copy") {

            }
        }
    }

    func color(for value: Matrix.Scalar) -> Color {
        let base = Color.primary
        if value.isNaN || value.isInfinite {
            return .yellow
        }
        else if value < 0 {
            return base.mix(with: .red, by: 0.5)
        }
        else if value > 0 {
            return base.mix(with: .green, by: 0.5)
        }
        return base
    }
}

extension simd_double4x4: @retroactive FormattableMatrix {
    public var columnCount: Int { return 4 }
    public var rowCount: Int { return 4 }
}
