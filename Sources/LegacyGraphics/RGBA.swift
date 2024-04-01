import CoreGraphics
import Geometry
import simd

// TODO: Replace with SIMD4<>?

// TODO: Deprecate
public typealias RGBA = SIMD4<UInt8>

//// @available(*, deprecated, message: "Use SIMD4<UInt8> instead") TODO: Will deprecate
// public struct RGBA: Equatable {
//    public var r: UInt8
//    public var g: UInt8
//    public var b: UInt8
//    public var a: UInt8
//
//    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
//        self.r = r
//        self.g = g
//        self.b = b
//        self.a = a
//    }
// }

public extension RGBA {
    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self = .init(r, g, b, a)
    }

    var r: Scalar {
        get { x }
        set { x = newValue }
    }

    var g: Scalar {
        get { y }
        set { y = newValue }
    }

    var b: Scalar {
        get { z }
        set { z = newValue }
    }

    var a: Scalar {
        get { w }
        set { w = newValue }
    }

    // TODO: FIXME
//    static func doubles(r: Double, g: Double, b: Double, a: Double = 1.0) -> RGBA {
//        RGBA(doubles: [r, g, b, a])
//    }

    // TODO: FIXME
//    init(doubles components: [Double]) {
//        let components = components.map(RGBA.convert)
//        self = RGBA(r: components[0], g: components[1], b: components[2], a: components.count > 3 ? components[3] : 255)
//    }

    // TODO: FIXME
//    private static func convert(_ value: Double) -> UInt8 {
//        UInt8(Everything.clamp(value * 255, lower: 0.0, upper: 255.0))
//    }
}

public extension RGBA {
    static let black = RGBA(r: 0, g: 0, b: 0)
}

public extension RGBA {
    var cgColor: CGColor {
        fatalError("Unimplemented")
    }

    // TODO: FIXME
//    init(cgColor: CGColor) {
//        switch cgColor.numberOfComponents {
//        case 2:
//            guard let components = cgColor.components?.map(Double.init) else {
//                fatalError("Unimplemented")
//            }
//            self = RGBA.doubles(r: components[0], g: components[0], b: components[0], a: Double(cgColor.alpha))
//        case 4:
//            guard let components = cgColor.components?.map(Double.init) else {
//                fatalError("Unimplemented")
//            }
//            self = RGBA.doubles(r: components[0], g: components[1], b: components[2], a: Double(cgColor.alpha))
//        default:
//            fatalError("Unimplemented")
//        }
//    }
}

// TODO: FIXME
// public extension Array2D where Element == RGBA {
//    init(size: IntSize) {
//        self = Array2D<RGBA>(repeating: RGBA.black, size: size)
//    }
// }
