import SIMDSupport
import SwiftUI

public protocol PolygonConvertable {
    func toPolygons() -> [Polygon<SimpleVertex>]
}

extension Box: PolygonConvertable where Point == SIMD3<Float> {
    public func toPolygons() -> [Polygon<SimpleVertex>] {
        let polygons = [
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, min.z), normal: .init(x: -1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, min.z), normal: .init(x: -1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, max.z), normal: .init(x: -1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, max.z), normal: .init(x: -1, y: 0, z: 0)),
            ]).flipped(),

            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, min.z), normal: .init(x: 1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, max.z), normal: .init(x: 1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, max.z), normal: .init(x: 1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, min.z), normal: .init(x: 1, y: 0, z: 0)),
            ]).flipped(),
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, min.z), normal: .init(x: 0, y: -1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, min.z), normal: .init(x: 0, y: -1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, max.z), normal: .init(x: 0, y: -1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, max.z), normal: .init(x: 0, y: -1, z: 0)),
            ]),
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, min.z), normal: .init(x: 0, y: 1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, max.z), normal: .init(x: 0, y: 1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, max.z), normal: .init(x: 0, y: 1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, min.z), normal: .init(x: 0, y: 1, z: 0)),
            ]),
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
            ]),
            Polygon(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
            ]),
        ]
        return polygons
    }
}

extension Sphere: PolygonConvertable {
    public func toPolygons() -> [Polygon<SimpleVertex>] {
        let slices = 12
        let stacks = 12
        var polygons: [Polygon<SimpleVertex>] = []
        func vertex(_ theta: Angle, _ phi: Angle) -> SimpleVertex {
            let dir = SIMD3<Float>(SIMD3<Double>(cos(theta.radians) * sin(phi.radians), cos(phi.radians), sin(theta.radians) * sin(phi.radians)))
            return SimpleVertex(position: dir * radius + center, normal: dir)
        }
        for i in 0 ..< slices {
            for j in 0 ..< stacks {
                let v1 = vertex(.degrees(Double(i) / Double(slices) * 360), .degrees(Double(j) / Double(stacks) * 180))
                let v2 = vertex(.degrees(Double(i + 1) / Double(slices) * 360), .degrees(Double(j) / Double(stacks) * 180))
                let v3 = vertex(.degrees(Double(i + 1) / Double(slices) * 360), .degrees(Double(j + 1) / Double(stacks) * 180))
                let v4 = vertex(.degrees(Double(i) / Double(slices) * 360), .degrees(Double(j + 1) / Double(stacks) * 180))
                polygons.append(Polygon(vertices: [v1, v2, v3]))
                polygons.append(Polygon(vertices: [v1, v3, v4]))
            }
        }
        return polygons
    }
}