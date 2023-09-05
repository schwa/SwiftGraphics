import Accelerate
import Foundation
import simd
//
public extension Array2D where Element == Float {
    static func * (lhs: Self, rhs: Self) -> Self {
        var result = Array2D(repeating: 0, size: [lhs.size.height, rhs.size.height])
        // Stride: https://developer.apple.com/documentation/accelerate/controlling_vdsp_operations_with_stride
        // swiftlint:disable multiline_arguments
        vDSP_mmul(
            lhs.flatStorage, 1,
            rhs.flatStorage, 1,
            &result.flatStorage, 1,
            UInt(lhs.size.height), // The number of rows in matrices A and C.
            UInt(rhs.size.width), // The number of columns in matrices B and C.
            UInt(lhs.size.width) // The number of columns in matrix A and the number of rows in matrix B.
        )
        // swiftlint:enable multiline_arguments
        return result
    }
}

public extension Array2D {
    init(_ v: simd_float4x4) where Element == Float {
        // TODO: this is _row major_
        self = Array2D(size: [4, 4]) { point in
            v[point.x][point.y]
        }
    }
}

// TODO: Move
public extension Array2D {
    init(columns: [[Element]]) {
        self = Array2D(flatStorage: Array(columns.joined()), size: [columns.count, columns.first?.count ?? 0]).transposed()
    }

    func transposed() -> Self {
        Array2D(size: [size.height, size.width]) { point in
            self[point.y, point.x]
        }
    }
}
