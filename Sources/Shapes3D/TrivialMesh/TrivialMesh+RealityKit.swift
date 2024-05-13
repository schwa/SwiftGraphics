import MetalSupport
import ModelIO
import RealityKit

public extension MeshDescriptor {
    init(trivialMesh mesh: TrivialMesh<SimpleVertex>) {
        self = MeshDescriptor()
        // TODO: We're ignoring texture coordinates for now.
        assert(mesh.isValid)
        assert(!mesh.indices.isEmpty)
        assert(mesh.indices.count < UInt32.max)
        positions = MeshBuffers.Positions(mesh.vertices.map(\.position))
        normals = MeshBuffers.Normals(mesh.vertices.map(\.normal))
        primitives = .triangles(mesh.indices.map { UInt32($0) })
    }
}

public extension ModelComponent {
    init(trivialMesh mesh: TrivialMesh<SimpleVertex>, materials: [Material] = []) throws {
        let meshDescriptor = MeshDescriptor(trivialMesh: mesh)
        let meshResource = try MeshResource.generate(from: [meshDescriptor])
        self = ModelComponent(mesh: meshResource, materials: materials)
    }
}

public extension ModelEntity {
    convenience init(trivialMesh mesh: TrivialMesh<SimpleVertex>, materials: [Material] = []) throws {
        let modelComponent = try! ModelComponent(trivialMesh: mesh, materials: materials)
        self.init()
        components.set(modelComponent)
    }
}
