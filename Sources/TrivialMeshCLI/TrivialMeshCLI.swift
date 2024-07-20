import ArgumentParser
import Foundation
import Shapes3D

@main
struct TrivialMeshCLI: ParsableCommand {
    //    @Flag(help: "Include a counter with each repetition.")
    //    var includeCounter = false
    //
    //    @Option(name: .shortAndLong, help: "The number of times to repeat 'phrase'.")
    //    var count: Int? = nil
    //
    //    @Argument(help: "The phrase to repeat.")
    //    var phrase: String

    mutating func run() throws {
        //        let mesh = TrivialMesh(cylinder: Cylinder(radius: 0.5, depth: 1), segments: 16)
        //        let url = URL(fileURLWithPath: "/tmp/cylinder.ply")
        //        try mesh.write(to: url)

        let mesh = TrivialMesh.generatePlane(extent: [10, 10], segments: [4, 4])
        let url = URL(fileURLWithPath: "/tmp/mesh.stl")
        try mesh.write(to: url)
    }
}

// ply
// format ascii 1.0
// comment object: Obj01
// element vertex 4
// property float x
// property float y
// property float z
// element face 2
// property list uchar int vertex_index
// end_header
// 0 0 0
// 10 0 0
// 0 10 0
// 10 10 0
// 3 0 3 2
// 3 0 1 3
