import Foundation
import SwiftGraphicsDemosSupport

@main
enum Main {
    static func main() async throws {
        let source = """
            ply
            format binary_little_endian 1.0
            element vertex 1
            property float x
            property float y
            property float z
            element face 1
            property list uchar uint vertex_indices
            end_header
            1 2 3
            4 0 0 0 0
            """
        let ply = try Ply(source: source)
        print(ply.elements[0].records[0].values[0].float)
        print(ply.elements[0].records[1].values[0].float)

    }
}
