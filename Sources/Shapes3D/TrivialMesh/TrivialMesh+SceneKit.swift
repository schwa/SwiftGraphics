import Foundation
import SceneKit

public extension SCNNode {
    convenience init(trivialMesh mesh: TrivialMesh<SimpleVertex>, color: CGColor) throws {
        self.init()
        let positions = SCNGeometrySource(vertices: mesh.vertices.map { SCNVector3($0.position) })
        let normals = SCNGeometrySource(normals: mesh.vertices.map { SCNVector3($0.normal) })
        let textureCoordinates = SCNGeometrySource(textureCoordinates: mesh.vertices.map { CGPoint(x: Double($0.textureCoordinate.x), y: Double($0.textureCoordinate.y)) })
        let elements = SCNGeometryElement(indices: mesh.indices.map { UInt32($0) }, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [positions, normals, textureCoordinates], elements: [elements])
        let material = SCNMaterial()
        material.diffuse.contents = color
        geometry.replaceMaterial(at: 0, with: material)
        self.geometry = geometry
    }
}
