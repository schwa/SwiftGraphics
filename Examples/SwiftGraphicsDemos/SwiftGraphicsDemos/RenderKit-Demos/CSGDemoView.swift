import SwiftUI
import RenderKit
import RenderKitShaders
import Everything
import RenderKitScratch

struct CSGDemoView: View, DefaultInitializableView {
    var body: some View {
        CSGDemoView_()
    }
}
struct CSGDemoView_: View {
    let a: CSG<SimpleVertex>
    let b: CSG<SimpleVertex>
    let c: CSG<SimpleVertex>
    let node: Node<SimpleVertex>

    init() {
        a = Box(min: [-5, -5, -5], max: [5, 5, 5]).toCSG()
        b = Box(min: [-10, -2, -2], max: [0, 2, 2]).toCSG()
        //b = Sphere(center: [5, 0, 0], radius: 5).toCSG()

//        a = CGRect(x: -5, y: -5, width: 10, height: 10).toCSG()
//        b = CGRect(x: 0, y: 0, width: 10, height: 10).toCSG()

        do {
            let a = Node(polygons: a.polygons)
            let b = Node(polygons: b.polygons)
            a.clip(to: b)
            node = a
        }

        c = a.union(b)

        try! a.toPLY().write(to: URL(filePath: "test-a.ply"), atomically: true, encoding: .ascii)
        try! b.toPLY().write(to: URL(filePath: "test-b.ply"), atomically: true, encoding: .ascii)
        try! c.toPLY().write(to: URL(filePath: "test-c.ply"), atomically: true, encoding: .ascii)

        URL(filePath: "test-c.ply").reveal()

        //        let plane = Plane(normal: [0, 1, 0], w: 5)
//        let csg = sphere.toCSG()
//        print(csg.polygons.count)
//        let (a, b) = csg.split(plane: plane)
//        print(a.polygons.count)
//        print(b.polygons.count)
//        print(a.polygons.count + b.polygons.count)
    }

    var body: some View {
        Canvas { context, size in
            let transform = CGAffineTransform(scaleX: 30, y: 30)
            context.translateBy(x: size.width / 2, y: size.height / 2)
//            context.draw(csg: a, transform: transform, with: .color(.red))
//            context.draw(csg: b, transform: transform, with: .color(.green))
            //context.draw(csg: c, transform: transform, with: .color(.blue))
            context.draw(node: node, transform: transform)
        }
    }
}

extension GraphicsContext {
    func draw <V>(csg: CSG<V>, transform: CGAffineTransform = .identity, with shading: Shading) where V: VertexLike {
        for polygon in csg.polygons {
            let a = polygon.vertices[0].position
            let b = polygon.vertices[1].position
            let c = polygon.vertices[2].position
            let dir = simd_normalize(simd_cross(b - a, c - a))
            guard dir.z > 0 else {
                continue
            }
            let lines = polygon.vertices.map { CGPoint($0.position.xy) }
            let path = Path { path in
                path.addLines(lines)
                path.closeSubpath()
            }
            .applying(transform)
            stroke(path, with: shading)
        }
    }

    func draw(node: Node<SimpleVertex>, transform: CGAffineTransform = .identity) {
        let n = abs(ObjectIdentifier(node).hashValue) % kellyColors.count
        let rgb = kellyColors[n]
        let color = Color(red: Double(rgb.0), green: Double(rgb.1), blue: Double(rgb.2))
        for polygon in node.polygons {
            let a = polygon.vertices[0].position
            let b = polygon.vertices[1].position
            let c = polygon.vertices[2].position
            let dir = simd_normalize(simd_cross(b - a, c - a))
            guard dir.z > 0 else {
                continue
            }
            let lines = polygon.vertices.map { CGPoint($0.position.xy) }
            let path = Path { path in
                path.addLines(lines)
                path.closeSubpath()
            }
            .applying(transform)
            stroke(path, with: .color(color))
        }
        if let front = node.front {
            draw(node: front, transform: transform)
        }
        if let back = node.back {
            draw(node: back, transform: transform)
        }
    }
}

extension URL {
    func reveal() {
#if os(macOS)
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
#endif
    }
}
