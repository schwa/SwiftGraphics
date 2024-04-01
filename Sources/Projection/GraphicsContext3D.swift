import simd
import SwiftUI

public struct GraphicsContext3D {
    public var graphicsContext2D: GraphicsContext
    public var projection: Projection3D
    public var rasterizerOptions: Rasterizer.Options

    public var rasterizer: Rasterizer {
        Rasterizer(graphicsContext: self, options: rasterizerOptions)
    }

    public init(graphicsContext2D: GraphicsContext, projection: Projection3D) {
        self.graphicsContext2D = graphicsContext2D
        self.projection = projection
        rasterizerOptions = .default
    }

    public func stroke(path: Path3D, with shading: GraphicsContext.Shading, lineWidth: Double = 1) {
        stroke(path: path, with: shading, style: .init(lineWidth: lineWidth))
    }

    public func stroke(path: Path3D, with shading: GraphicsContext.Shading, style: StrokeStyle) {
        let viewProjectionTransform = projection.projectionTransform * projection.viewTransform
        let path = Path { path2D in
            for element in path.elements {
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
        graphicsContext2D.stroke(path, with: shading, style: style)
    }
}
