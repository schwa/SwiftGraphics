import RenderKit

extension YAMesh {
    func convert(to other: VertexDescriptor) throws -> YAMesh {
        if vertexDescriptor == other {
            return self
        }

        print(vertexDescriptor)
        print(other)

        fatalError()
    }

    func pack(to other: VertexDescriptor) throws -> YAMesh {
        if vertexDescriptor == other {
            return self
        }

        print(vertexDescriptor)
        print(other)

        fatalError()
    }
}

extension VertexDescriptor {
    var isPacked: Bool {
        return layouts.count == 1
    }
}
