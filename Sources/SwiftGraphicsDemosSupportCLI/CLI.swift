import Foundation
import SwiftGraphicsDemosSupport

@main
enum Main {
    static func main() async throws {
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
//            4 0 0 0 0
//            """
//        let ply = try Ply(source: source)
//        print(ply)
//        print(ply.elements[0].records[0].to(definition: ply.header.elements[0], ofType: SIMD3<Float>.self)!)
//        print(ply.elements[0].records[1].to(definition: ply.header.elements[0], ofType: SIMD3<Float>.self)!)
//        print(ply.elements[0].records[0].values[0].float!)
//        print(ply.elements[0].records[1].values[0].float!)

        let url = Bundle.module.url(forResource: "CubeBinary", withExtension: "ply")!
        var ply = try Ply(url: url, processElements: true)
        print(ply)
        print(ply.processedElements)
        print(try ply.elements)

    }
}
