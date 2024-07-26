import Everything
import Foundation

// Alumbaugh, T. J., & Jiao, X. (2005). Compact array-based mesh data structures. In Proceedings of the 14th International Meshing Roundtable (pp. pages). https://link.springer.com/chapter/10.1007/3-540-29090-7_29
// Note: the mesh cares about topology and doesn't care about position of vertices. Vertices can be represented as an id or index.
// TODO: Everything is 1 based (for compatibility with paper) but needs to become 0 based for sanity
// TODO: This file is a mess and doesn't match what a final API should look like
// TODO: Goal is to unit test against data provided in paper and then improve API while keeping tests passing.

struct CompactHalfEdgeMesh {
    enum Mesh {
    }

    enum Face {
    }

    enum Edge {
    }

    enum HalfEdge {
    }

    enum Vertex {
    }

    typealias FaceID = Tagged<Face, OneBasedIndex>
    typealias FaceEdgeID = Tagged<(Face, Edge), OneBasedIndex>
    typealias VertexID = Tagged<Vertex, OneBasedIndex>
    typealias HalfEdgeID = Tagged<HalfEdge, (FaceID, FaceEdgeID)>

    var EC: [(face: FaceID, vertices: [VertexID])] = [] // element connectivity
    var V2e: [HalfEdgeID] = []
    var E2e: [[HalfEdgeID]] = []
    var B2e: [HalfEdgeID] = []

    init(EC: [(FaceID, [VertexID])], V2e: [HalfEdgeID] = [], E2e: [[HalfEdgeID]] = [], B2e: [HalfEdgeID] = []) {
        self.EC = EC
        self.V2e = V2e
        self.E2e = E2e
        self.B2e = B2e
    }
}

extension CompactHalfEdgeMesh {
    // One-to-any downward incidence

    // ith edge (half-edge) of face f: return (f, i)
    func halfEdge(face f: FaceID, index i: FaceEdgeID) -> HalfEdgeID {
        .init(f, i)
    }

    func vertexCount(face: FaceID) -> Int {
        EC[face.zeroBased!].vertices.count
    }

    // ith vertex of face f: return EC(f, i)
    func vertex(face: FaceID, faceEdge: FaceEdgeID) -> VertexID {
        EC[face.zeroBased!].vertices[faceEdge.zeroBased!]
    }

    // origin of non-border half-edge (f, i): return EC(f, i)
    // TODO

    // One-to-any upward incidence

    // the incident face of a non-border half-edge (f, i): return f
    func face(halfEdge: HalfEdgeID) -> FaceID {
        halfEdge.f
    }

    // an incident half-edge of uth vertex: return V2e(v)
    func halfEdge(vertex: VertexID) -> HalfEdgeID {
        V2e[vertex.zeroBased!]
    }

    // Adjacency

    // opposite of non-border half-edge (f, i): return E2e(f, i)
    func oppositeOfNonBorder(_ fi: HalfEdgeID) -> HalfEdgeID {
        E2e[fi.f.zeroBased!][fi.i.zeroBased!]
    }

    // opposite of border half-edge (b, 0): return B2e(b)
    func oppositeOfBorder(_ fi: HalfEdgeID) -> HalfEdgeID {
        assert(fi.i == 0)
        return B2e[fi.f.zeroBased!]
    }

    // previous of non-border half-edge (f, i): return (f, mod(i + m - 2, m) + 1)
    func previousOfNonBorderHalfEdge(fi: HalfEdgeID) -> HalfEdgeID {
        let m = EC[fi.f.zeroBased!].vertices.count
        let i = (fi.i.index + m - 2) % m + 1 // meh
        return HalfEdgeID(fi.f, .init(rawValue: .init(rawValue: i)))
    }

    // next of non-border half-edge (f,i): return (f, mod(I, m) + 1)
    func nextOfNonBorderHalfEdge(fi: HalfEdgeID) -> HalfEdgeID {
        let m = EC[fi.f.zeroBased!].vertices.count
        let i = (fi.i.index) % m + 1 // meh
        return HalfEdgeID(fi.f, .init(rawValue: .init(rawValue: i)))
    }

    // Boundary classification
    //    half-edge (f, i): return i = 0
    func isBoundary(fi: HalfEdgeID) -> Bool {
        fi.i == 0
    }

    // vertex v: return V2e(v).second= 0
    func isBoundary(vertex: VertexID) -> Bool {
        V2e[vertex.zeroBased!].i == 0
    }
}

extension CompactHalfEdgeMesh {
    // swiftlint:disable:next unavailable_function
    init(connectivity: [(FaceID, [VertexID])]) {
        unimplemented()
    }
}

struct OneBasedIndex: Hashable, Comparable, RawRepresentable {
    var rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    var zeroBased: Int? {
        rawValue <= 0 ? nil : rawValue - 1
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension OneBasedIndex: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        rawValue = value
    }
}

extension OneBasedIndex: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(rawValue)"
    }
}

extension CompactHalfEdgeMesh.HalfEdgeID: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(rawValue.0), \(rawValue.1)"
    }
}

extension Tagged where RawValue == OneBasedIndex {
    var index: Int {
        rawValue.rawValue
    }

    var zeroBased: Int? {
        rawValue.zeroBased
    }
}

extension CompactHalfEdgeMesh.HalfEdgeID {
    init(_ f: CompactHalfEdgeMesh.FaceID, _ i: CompactHalfEdgeMesh.FaceEdgeID) {
        self.init((f, i))
    }

    var f: CompactHalfEdgeMesh.FaceID {
        rawValue.0
    }
    var i: CompactHalfEdgeMesh.FaceEdgeID {
        rawValue.1
    }
}
