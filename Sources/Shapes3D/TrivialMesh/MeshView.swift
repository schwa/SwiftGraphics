#if os(visionOS)
    import Foundation
    import RealityKit
    import SwiftUI

    public struct MeshView: View {
        let mesh: TrivialMesh<SimpleVertex>

        public init(mesh: TrivialMesh<SimpleVertex>) {
            self.mesh = mesh
        }

        public var body: some View {
            RealityView { content in
                let entity = try! ModelEntity(trivialMesh: mesh)
                entity.orientation = .init(angle: .pi / 2, axis: [1, 0, 0])
                print(entity.visualBounds(relativeTo: nil))
                content.add(entity)
            }
        }
    }

    #Preview {
        MeshView(mesh: TrivialMesh(cylinder: Cylinder3D(radius: 0.1, depth: 0.01), segments: 24))
        // MeshView(mesh: TrivialMesh(circleRadius: 1, segments: 24))
    }
#endif
