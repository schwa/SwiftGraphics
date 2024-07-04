// from https://github.com/evanw/csg.js/blob/master/csg.js

import BaseSupport
import Foundation
import MetalSupport
import Shapes3D
import simd
import SIMDSupport

struct CSG<Vertex> where Vertex: VertexLike {
    typealias Polygon = Polygon3D<Vertex>

    var polygons: [Polygon]
}

extension CSG {
    init(node: CSGNode<Vertex>) {
        polygons = node.allPolygons
    }
}

extension CSG where Vertex == SimpleVertex {
    // Return a new CSG solid representing space in either this solid or in the
    // solid `csg`. Neither this solid nor the solid `csg` are modified.
    //
    //     A.union(B)
    //
    //     +-------+            +-------+
    //     |       |            |       |
    //     |   A   |            |       |
    //     |    +--+----+   =   |       +----+
    //     +----+--+    |       +----+       |
    //          |   B   |            |       |
    //          |       |            |       |
    //          +-------+            +-------+
    //
    func union(_ other: Self) -> Self {
        let a = CSGNode(polygons: polygons)
        let b = CSGNode(polygons: other.polygons)
        a.clip(to: b)
        a.dump()

        //        try! CSG(node: a).toPLY().write(to: URL(filePath: "intermediate-1.ply"), atomically: true, encoding: .ascii)
        b.clip(to: a)
        b.invert()
        b.clip(to: a)
        return Self(polygons: a.allPolygons + b.allPolygons)
    }

    // Return a new CSG solid representing space in this solid but not in the
    // solid `csg`. Neither this solid nor the solid `csg` are modified.
    //
    //     A.subtract(B)
    //
    //     +-------+            +-------+
    //     |       |            |       |
    //     |   A   |            |       |
    //     |    +--+----+   =   |    +--+
    //     +----+--+    |       +----+
    //          |   B   |
    //          |       |
    //          +-------+
    //
    func subtracting(_ other: Self) -> Self {
        let a = CSGNode(polygons: polygons)
        let b = CSGNode(polygons: other.polygons)
        a.invert()
        a.clip(to: b)
        b.clip(to: a)
        b.invert()
        b.clip(to: a)
        var polygons = a.allPolygons + b.allPolygons
        a.invert()
        polygons = a.allPolygons + b.allPolygons
        return Self(polygons: polygons)
    }

    // Return a new CSG solid representing space both this solid and in the
    // solid `csg`. Neither this solid nor the solid `csg` are modified.
    //
    //     A.intersect(B)
    //
    //     +-------+
    //     |       |
    //     |   A   |
    //     |    +--+----+   =   +--+
    //     +----+--+    |       +--+
    //          |   B   |
    //          |       |
    //          +-------+
    //
    func intersecting(_ other: Self) -> Self {
        let a = CSGNode(polygons: polygons)
        let b = CSGNode(polygons: other.polygons)
        a.invert()
        b.clip(to: a)
        b.invert()
        a.clip(to: b)
        b.clip(to: a)
        var polygons = a.allPolygons + b.allPolygons
        a.invert()
        polygons = a.allPolygons + b.allPolygons
        return Self(polygons: polygons)
    }

    func inverted() -> Self {
        Self(polygons: polygons.map { $0.flipped() })
    }

    func split(plane: Plane3D) -> (Self, Self) {
        var coplanarFront: [Polygon] = []
        var coplanarBack: [Polygon] = []
        var front: [Polygon] = []
        var back: [Polygon] = []

        for polygon in polygons {
            let result = polygon.split(plane: plane)
            coplanarFront += result.coplanarFront
            coplanarBack += result.coplanarBack
            front += result.front
            back += result.back
        }

        return (CSG(polygons: coplanarFront + front), CSG(polygons: coplanarBack + back))
    }
}

// MARK: -

class CSGNode<Vertex> where Vertex: VertexLike {
    typealias Polygon = Polygon3D<Vertex>

    var plane: Plane3D?
    var front: CSGNode?
    var back: CSGNode?
    var polygons: [Polygon]

    init(plane: Plane3D? = nil, front: CSGNode? = nil, back: CSGNode? = nil, polygons: [Polygon] = []) {
        self.plane = plane
        self.front = front
        self.back = back
        self.polygons = polygons
    }

    convenience init(polygons: [Polygon]) {
        self.init()
        insert(polygons: polygons)
    }

    // Build a BSP tree out of `polygons`. When called on an existing tree, the
    // new polygons are filtered down to the bottom of the tree and become new
    // nodes there. Each set of polygons is partitioned using the first polygon
    // (no heuristic is used to pick a good split).
    func insert(polygons: [Polygon]) {
        temporarilyDisabled() // TODO: FIXME
        //        if polygons.isEmpty {
        //            return
        //        }
        //
        //        if plane == nil {
        //            plane = Plane3D(points: polygons[0].vertices)
        //        }
        //
        //        var front: [Polygon] = []
        //        var back: [Polygon] = []
        //
        //        for polygon in polygons {
        //            let result = polygon.split(plane: plane!)
        //            front += result.front
        //            back += result.back
        //            self.polygons += result.coplanarFront + result.coplanarBack
        //        }
        //
        //        if !front.isEmpty {
        //            if self.front == nil {
        //                self.front = Node(polygons: [])
        //            }
        //            self.front!.insert(polygons: front)
        //        }
        //
        //        if !back.isEmpty {
        //            if self.back == nil {
        //                self.back = Node(polygons: [])
        //            }
        //            self.back!.insert(polygons: back)
        //        }
    }

    // Convert solid space to empty space and empty space to solid space.
    func invert() {
        temporarilyDisabled() // TODO: FIXME
        //        polygons = polygons.map { $0.flipped() }
        //        plane!.flip()
        //        front?.invert()
        //        back?.invert()
        //        swap(&front, &back)
    }

    // Recursively remove all polygons in `polygons` that are inside this BSP tree.
    // swiftlint:disable:next unavailable_function
    func clip(polygons: [Polygon]) -> [Polygon] {
        // TODO: FIXME
        fatalError("Unimplemented")
        //        guard let plane else {
        //            return []
        //        }
        //
        //        var front: [Polygon] = []
        //        var back: [Polygon] = []
        //        // TODO: FIX ME
        //        temporarilyDisabled()
        //        for polygon in polygons {
        //            let result = polygon.split(plane: plane)
        //            front += result.front + result.coplanarFront
        //            back += result.back + result.coplanarBack
        //        }
        //
        //        if self.front != nil {
        //            front = self.front!.clip(polygons: front)
        //        }
        //        if self.back != nil {
        //            back = self.back!.clip(polygons: back)
        //        }
        //        return front + back
    }

    // Remove all polygons in this BSP tree that are inside the other BSP tree.
    func clip(to node: CSGNode) {
        polygons = node.clip(polygons: polygons)
        if let front {
            front.clip(to: node)
        }
        if let back {
            back.clip(to: node)
        }
    }

    var allPolygons: [Polygon] {
        var polygons = polygons
        if let front {
            polygons += front.allPolygons
        }
        if let back {
            polygons += back.allPolygons
        }
        return polygons
    }
}

extension CSGNode {
    func dump(depth: Int = 0) {
        let indent = String(repeating: "  ", count: depth)
        print("\(indent)NODE: \(polygons.count) polygons. \(plane!)")
        if let front {
            print("\(indent)front:")
            front.dump(depth: depth + 1)
        }
        if let back {
            print("\(indent)back:")
            back.dump(depth: depth + 1)
        }
    }
}

private enum SplitType: Int {
    case coplanar = 0
    case front = 1
    case back = 2
    case spanning = 3
}

extension SplitType {
    static func | (lhs: Self, rhs: Self) -> Self {
        SplitType(rawValue: lhs.rawValue | rhs.rawValue)!
    }

    static func |= (lhs: inout Self, rhs: Self) {
        lhs = lhs | rhs
    }
}

extension Polygon3D where Vertex == SimpleVertex {
    func split(plane splitter: Plane3D) -> (coplanarFront: [Self], coplanarBack: [Self], front: [Self], back: [Self]) {
        let EPSILON: Float = 1e-5

        var coplanarFront: [Self] = []
        var coplanarBack: [Self] = []
        var front: [Self] = []
        var back: [Self] = []

        var polygonType = SplitType.coplanar
        var types: [SplitType] = []
        for vertex in vertices {
            let t = simd.dot(splitter.normal, vertex.position) - splitter.w
            let type: SplitType = (t < -EPSILON) ? .back : (t > EPSILON) ? .front : .coplanar
            polygonType |= type
            types.append(type)
        }
        switch polygonType {
        case .coplanar:
            if splitter.normal.dot(plane.normal) - plane.w > 0 {
                coplanarFront.append(self)
            }
            else {
                coplanarBack.append(self)
            }
        case .front:
            front.append(self)
        case .back:
            back.append(self)
        case .spanning:
            fatalError("Unimplemented")
        // TODO: FIXME

        // swiftlint:disable local_doc_comment
        //            var f: [Vertex] = []
        //            var b: [Vertex] = []
        //            for (i, j) in zip(vertices, types).circularPairs() {
        //                let (vi, ti) = i
        //                let (vj, tj) = j
        //                if ti != .back {
        //                    f.append(vi)
        //                }
        //                if ti != .front {
        //                    b.append(vi)
        //                }
        //                temporarilyDisabled()
        //                // TODO: FIXME
        ////                if ti | tj == .spanning {
        ////                    let t = (splitter.w - splitter.normal.dot(vi.position)) / splitter.normal.dot(vj.position - vi.position)
        ////                    let v = vi.interpolate(vj, t)
        ////                    f.append(v)
        ////                    b.append(v)
        ////                }
        //            }
        //            if f.count >= 3 {
        //                front.append(Polygon3D(vertices: f))
        //            }
        //            if b.count >= 3 {
        //                back.append(Polygon3D(vertices: b))
        //            }
        }
        return (coplanarFront, coplanarBack, front, back)
    }
}
