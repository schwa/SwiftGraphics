import simd

/**
 A protocol to provide common methods for the SIMD matrix types
 */
public protocol SIMDMatrix {
    associatedtype Scalar: FloatingPoint
    associatedtype ColumnType: SIMD
    associatedtype RowType: SIMD

    init(_ scalar: Scalar)
}

// MARK: -

/* simd_<type><columns>x<rows>*/

extension simd_float4x4: SIMDMatrix {
    public typealias ColumnType = SIMD4<Float>
    public typealias RowType = SIMD4<Float>
}

extension simd_float3x4: SIMDMatrix {
    public typealias ColumnType = SIMD3<Float>
    public typealias RowType = SIMD4<Float>
}

extension simd_float4x3: SIMDMatrix {
    public typealias ColumnType = SIMD4<Float>
    public typealias RowType = SIMD3<Float>
}

extension simd_float3x3: SIMDMatrix {
    public typealias ColumnType = SIMD3<Float>
    public typealias RowType = SIMD3<Float>
}

// extension simd_float3x2: SIMDMatrix {
//    typealias Column = SIMD4<Float>
// }
//
// extension simd_float2x3: SIMDMatrix {
//    typealias Column = SIMD4<Float>
// }
//
// extension simd_float2x2: SIMDMatrix {
//    typealias Column = SIMD4<Float>
// }

// MARK: -

public extension SIMDMatrix {
    static var identity: Self { Self(1) }
}

// swiftlint:disable:next type_name
public protocol _MatrixExtra {
    var size: SIMD2<Int> { get }
}

extension simd_float3x3: _MatrixExtra {
    public typealias Scalar = Float

    public var size: SIMD2<Int> {
        [3, 3]
    }
}

extension simd_float3x4: _MatrixExtra {
    public typealias Scalar = Float

    public var size: SIMD2<Int> {
        [3, 4]
    }
}

extension simd_float4x4: _MatrixExtra {
    public typealias Scalar = Float

    public var size: SIMD2<Int> {
        [4, 4]
    }
}
