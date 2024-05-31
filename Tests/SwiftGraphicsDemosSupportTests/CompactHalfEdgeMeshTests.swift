import XCTest
@testable import SwiftGraphicsDemosSupport

class CompactHalfEdgeMeshTests: XCTestCase {
    func test1() {
/*
 1───────────▶2───────────▶3
 ▲ ╳──────────┬──────────╳ │
 │ │╲◀────── ▲│◀────── ▲╱│ │
 │ │ ╲   ┌─┐ ││  ┌─┐  ╱╱▲│ │
 │ │  ╲╲ │2│ │││ │3│ ╱╱╱││ │
 │ │   ╲╲└─┘ │││ └─┘╱╱╱ ││ │
 │ │    ╲╲   │││   ╱╱╱  ││ │
 │ │     ╲╲  │││  ╱╱╱   ││ │
 │ │  ┌─┐ ╲╲ │││ ╱╱╱┌─┐ ││ │
 │ │  │1│  ╲╲ ││ ╱╱ │4│ ││ │
 │ │  └─┘   ╲▼│▼╱╱  └─┘  │ │
 │ │         ╲│╱▼ ──────▶│ ▼
 4 ├──────────5──────────┤ 6
 ▲ │◀───────▲╱│╲╲───────▲│ │
 │ ││ ┌─┐  ╱╱╱│▲╲╲  ┌─┐ ││ │
 │ ││ │9│ ╱╱╱│││╲╲╲ │5│ ││ │
 │ ││ └─┘╱╱╱ │││ ╲╲╲└─┘ ││ │
 │ ││   ╱╱╱  │││  ╲╲╲   ││ │
 │ ││  ╱╱╱   │││   ╲╲╲  ││ │
 │ ││ ╱╱╱┌─┐ │││ ┌─┐╲╲╲ ││ │
 │ ││╱╱╱ │7│ │││ │6│ ╲╲╲ │ │
 │ │▼╱╱  └─┘ │││ └─┘  ╲╲▼│ │
 │ │╱▼ ──────▶│────────╲╲│ │
 │ ╳──────────┴──────────╳ ▼
 7◀───────────8◀───────────9
 */

        typealias Mesh = CompactHalfEdgeMesh
        let EC: [(Mesh.FaceID, [Mesh.VertexID])] = [
            (1, [1, 4, 5]),
            (2, [1, 5, 2]),
            (3, [2, 5, 3]),
            (4, [3, 5, 6]),
            (5, [6, 5, 9]),
            (6, [8, 9, 5]),
            (7, [7, 8, 5]),
            (8, [5, 4, 7]),
        ]

        let V2e: [Mesh.HalfEdgeID] = [
            .init((2, 0)), // 1
            .init((3, 0)), // 2
            .init((4, 0)), // 3
            .init((1, 0)), // 4
            .init((1, 3)), // 5
            .init((5, 0)), // 6
            .init((8, 0)), // 7
            .init((7, 0)), // 8
            .init((6, 0)), // 9
        ]

        let E2e: [[Mesh.HalfEdgeID]] = [
            [.init((1, 0)), .init((8, 1)), .init((2, 1))], // 1
            [.init((1, 3)), .init((3, 1)), .init((2, 0))], // 2
            [.init((2, 2)), .init((4, 1)), .init((3, 0))], // 3
            [.init((3, 2)), .init((5, 1)), .init((4, 0))], // 4
            [.init((4, 2)), .init((6, 2)), .init((5, 0))], // 5
            [.init((6, 0)), .init((5, 2)), .init((7, 2))], // 6
            [.init((7, 0)), .init((6, 3)), .init((8, 3))], // 7
            [.init((1, 2)), .init((8, 0)), .init((7, 3))], // 8
        ]

        let B2e: [Mesh.HalfEdgeID] = [
            .init((1, 1)), // 1
            .init((2, 3)), // 2
            .init((3, 3)), // 3
            .init((4, 3)), // 4
            .init((5, 3)), // 5
            .init((6, 1)), // 6
            .init((7, 1)), // 7
            .init((8, 2)), // 8
        ]


        let mesh = Mesh(EC: EC, V2e: V2e, E2e: E2e, B2e: B2e)

        XCTAssertEqual(mesh.vertex(face: 1, faceEdge: 1), 1)
        XCTAssertEqual(mesh.vertex(face: 1, faceEdge: 2), 4)
        XCTAssertEqual(mesh.vertex(face: 1, faceEdge: 3), 5)

        print(mesh.face(halfEdge: mesh.halfEdge(vertex: 1)))
        print(mesh.face(halfEdge: mesh.halfEdge(vertex: 2)))
        print(mesh.face(halfEdge: mesh.halfEdge(vertex: 3)))
        print(mesh.face(halfEdge: mesh.halfEdge(vertex: 4)))
        print(mesh.face(halfEdge: mesh.halfEdge(vertex: 5)))
        print(mesh.face(halfEdge: mesh.halfEdge(vertex: 6)))
        print(mesh.face(halfEdge: mesh.halfEdge(vertex: 7)))
        print(mesh.face(halfEdge: mesh.halfEdge(vertex: 8)))
        print(mesh.face(halfEdge: mesh.halfEdge(vertex: 9)))

    }
}
