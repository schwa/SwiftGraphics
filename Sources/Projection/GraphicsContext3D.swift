import simd
import SwiftUI

public struct GraphicsContext3D {
    public var graphicsContext2D: GraphicsContext
    public var projection: Projection3DHelper

    public init(graphicsContext2D: GraphicsContext, projection: Projection3DHelper) {
        self.graphicsContext2D = graphicsContext2D
        self.projection = projection
    }

    public func stroke(path: Path3D, with shading: GraphicsContext.Shading, lineWidth: Double = 1) {
        stroke(path: path, with: shading, style: .init(lineWidth: lineWidth))
    }

    public func stroke(path: Path3D, with shading: GraphicsContext.Shading, style: StrokeStyle) {
        let viewProjectionTransform = projection.projectionTransform * projection.viewTransform
        let path = path.project(projection, viewProjectionTransform: viewProjectionTransform)
        graphicsContext2D.stroke(path, with: shading, style: style)
    }

    public func fill(path: Path3D, with shading: GraphicsContext.Shading) {
        let viewProjectionTransform = projection.projectionTransform * projection.viewTransform
        let path = path.project(projection, viewProjectionTransform: viewProjectionTransform)
        graphicsContext2D.fill(path, with: shading)
    }
}

extension Path3D {
    func project(_ projection: Projection3DHelper, viewProjectionTransform: simd_float4x4) -> Path {
        Path { path2D in
            for element in elements {
                switch element {
                case .move(let point):
                    let transform = projection.clipTransform * viewProjectionTransform
                    var point = transform * SIMD4<Float>(point, 1.0)
                    point /= point.w
                    path2D.move(to: CGPoint(x: Double(point.x), y: Double(point.y)))
                case .addLine(let point):
                    let transform = projection.clipTransform * viewProjectionTransform
                    var point = transform * SIMD4<Float>(point, 1.0)
                    point /= point.w
                    path2D.addLine(to: CGPoint(x: Double(point.x), y: Double(point.y)))
                case .closePath:
                    path2D.closeSubpath()
                }
            }
        }
    }
}
