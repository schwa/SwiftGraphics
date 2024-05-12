import Algorithms
import Metal
import MetalSupport
import RenderKit
import RenderKitShaders
import simd

// swiftlint:disable conditional_returns_on_newline

struct WingedEdgeCollection {
    struct Face {
        typealias Index = [Self].Index

        var edge: Edge.Index
    }

    struct Edge {
        typealias Index = [Self].Index

        var originVertex: Vertex.Index
        var destinationVertex: Vertex.Index
        var edgeLeftClockwise: Self.Index?
        var edgeLeftCounterClockwise: Self.Index?
        var edgeRightClockwise: Self.Index?
        var edgeRightCounterClockwise: Self.Index?
        var faceLeft: Face.Index?
        var faceRight: Face.Index?
    }

    struct Vertex {
        typealias Index = [Self].Index

        var position: SIMD3<Float>
        var edge: Edge.Index
    }

    var faces: [Face]
    var edges: [Edge]
    var vertices: [Vertex]

    init() {
        faces = []
        edges = []
        vertices = []
    }

    init(faces: [Face], edges: [Edge], vertices: [Vertex]) {
        self.faces = faces
        self.edges = edges
        self.vertices = vertices
    }
}

extension WingedEdgeCollection {
    mutating func add(face positions: [SIMD3<Float>]) {
        let nextFaceIndex = faces.count
        let nextEdgeIndex = edges.count
        // Create vertices
        let vertexIndices = positions.map { position in
            vertices.append(.init(position: position, edge: nextEdgeIndex))
            return vertices.count - 1
        }
        // Create one edge for every two vertices
        let edgeIndices = vertexIndices
            .circularPairs()
            .map { originVertexIndex, destinationVertexIndex in
                edges.append(.init(
                    originVertex: originVertexIndex,
                    destinationVertex: destinationVertexIndex,
                    edgeLeftClockwise: nil,
                    edgeLeftCounterClockwise: nil,
                    edgeRightClockwise: nil,
                    edgeRightCounterClockwise: nil,
                    faceLeft: nil,
                    faceRight: nil
                ))
                return edges.count - 1
            }
        // Create face
        faces.append(.init(edge: edgeIndices.first!))
        // Connect edges
        for (edgeIndex, edge) in edgeIndices.enumerated() {
            let nextEdgeIndex = edgeIndices[(edgeIndex + 1) % edgeIndices.count]
            let previousEdgeIndex = edgeIndices[(edgeIndex - 1 + edgeIndices.count) % edgeIndices.count]
            edges[edge].edgeLeftClockwise = nextEdgeIndex
            edges[edge].edgeLeftCounterClockwise = previousEdgeIndex
            edges[edge].faceLeft = nextFaceIndex
            edges[nextEdgeIndex].edgeRightClockwise = edge
            edges[previousEdgeIndex].edgeRightCounterClockwise = edge
            edges[nextEdgeIndex].faceRight = nextFaceIndex
            edges[previousEdgeIndex].faceRight = nextFaceIndex
        }
        // Connect vertices
        for (edgeIndex, edge) in edgeIndices.enumerated() {
            let nextEdgeIndex = edgeIndices[(edgeIndex + 1) % edgeIndices.count]
            let previousEdgeIndex = edgeIndices[(edgeIndex - 1 + edgeIndices.count) % edgeIndices.count]
            vertices[edges[edge].originVertex].edge = edge
            vertices[edges[nextEdgeIndex].destinationVertex].edge = nextEdgeIndex
            vertices[edges[previousEdgeIndex].destinationVertex].edge = previousEdgeIndex
        }
    }
}

extension WingedEdgeCollection {
    var isValid: Bool {
        // Every edge has a face on the left and right
        for edge in edges {
            guard edge.faceLeft != nil else { return false }
            guard edge.faceRight != nil else { return false }
        }
        // Every edge has a clockwise and counter-clockwise edge on the left and right
        for edge in edges {
            guard edge.edgeLeftClockwise != nil else { return false }
            guard edge.edgeLeftCounterClockwise != nil else { return false }
            guard edge.edgeRightClockwise != nil else { return false }
            guard edge.edgeRightCounterClockwise != nil else { return false }
        }
        // Every edge has a vertex on the left and right
        for edge in edges {
            guard edge.originVertex != edge.destinationVertex else { return false }
        }
        return true
    }
}

extension WingedEdgeCollection {
    func edgeIndices(of face: Face) -> [Edge.Index] {
        var edgeIndices: [Edge.Index] = []
        var edge = face.edge
        repeat {
            edgeIndices.append(edge)
            edge = edges[edge].edgeLeftClockwise!
        }
        while edge != face.edge
        return edgeIndices
    }

    func edges(of face: Face) -> [Edge] {
        edgeIndices(of: face).map { edgeIndex in
            edges[edgeIndex]
        }
    }

    func vertexIndices(of face: Face) -> [Vertex.Index] {
        edges(of: face).map { edge in
            edge.originVertex
        }
    }

    func vertices(of face: Face) -> [Vertex] {
        edges(of: face).map { edge in
            vertices[edge.originVertex]
        }
    }

    var isAllTriangles: Bool {
        faces.allSatisfy { face in
            vertices(of: face).count == 3
        }
    }

    func toMesh(device: MTLDevice) throws -> YAMesh {
        enum Error: Swift.Error {
            case notAllTriangles
        }
        guard isAllTriangles else { throw Error.notAllTriangles }
        let indices: [UInt16] = faces.flatMap { face in
            vertexIndices(of: face).map { UInt16($0) }
        }
        let vertices: [SimpleVertex] = faces.flatMap { face in
            let vertices = self.vertices(of: face)
            return vertices.map { vertex in
                SimpleVertex(position: vertex.position, normal: .zero, textureCoordinate: .zero)
            }
        }
        return try YAMesh.simpleMesh(indices: indices, vertices: vertices, device: device)
    }
}
