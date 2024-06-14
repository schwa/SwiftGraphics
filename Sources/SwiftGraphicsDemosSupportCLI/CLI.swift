import Foundation
import SwiftGraphicsDemosSupport

@main
enum Main {
//    static func main() async throws {
//        let source = """
//            ply
//            format ascii 1.0
//            element vertex 2
//            property float x
//            property float y
//            property float z
//            element face 1
//            property list uchar uint vertex_indices
//            end_header
//            1 2 3
//            4 5 6
//            4 10 11 12 13
//            """
//        let ply = try Ply(string: source, processElements: true)
////        print(ply)
////        dump(ply.header)
////        print(ply.processedElements![0].records[0].to(definition: ply.header.elements[0], ofType: SIMD3<Float>.self)!)
////        print(ply.processedElements![0].records[1].to(definition: ply.header.elements[0], ofType: SIMD3<Float>.self)!)
////        print(ply.processedElements![1].records)
////
////        let url = Bundle.module.url(forResource: "CubeBinary", withExtension: "ply")!
////        var ply2 = try Ply(url: url, processElements: true)
////        print(ply2)
////        print(ply2.processedElements)
//
//        let url3 = Bundle.module.url(forResource: "test-splat.3-points-from-train", withExtension: "ply")!
//        var ply3 = try Ply(url: url3, processElements: true)
//        print(ply3)
//
//    }

    static func main() async throws {
        let source = """
            ply
            format binary_little_endian 1.0
            element vertex 3
            property float x
            property float y
            property float z
            property float nx
            property float ny
            property float nz
            property float f_dc_0
            property float f_dc_1
            property float f_dc_2
            property float f_rest_0
            property float f_rest_1
            property float f_rest_2
            property float f_rest_3
            property float f_rest_4
            property float f_rest_5
            property float f_rest_6
            property float f_rest_7
            property float f_rest_8
            property float f_rest_9
            property float f_rest_10
            property float f_rest_11
            property float f_rest_12
            property float f_rest_13
            property float f_rest_14
            property float f_rest_15
            property float f_rest_16
            property float f_rest_17
            property float f_rest_18
            property float f_rest_19
            property float f_rest_20
            property float f_rest_21
            property float f_rest_22
            property float f_rest_23
            property float f_rest_24
            property float f_rest_25
            property float f_rest_26
            property float f_rest_27
            property float f_rest_28
            property float f_rest_29
            property float f_rest_30
            property float f_rest_31
            property float f_rest_32
            property float f_rest_33
            property float f_rest_34
            property float f_rest_35
            property float f_rest_36
            property float f_rest_37
            property float f_rest_38
            property float f_rest_39
            property float f_rest_40
            property float f_rest_41
            property float f_rest_42
            property float f_rest_43
            property float f_rest_44
            property float opacity
            property float scale_0
            property float scale_1
            property float scale_2
            property float rot_0
            property float rot_1
            property float rot_2
            property float rot_3
            end_header\n
            """
        let header = try Ply.Header(source: source)
        print(header)
    }
}
