import simd
import SwiftUI

public struct Rasterizer {
    public struct Options {
        public var drawNormals = false
        public var normalsLength = 1.0
        public var shadeFragmentsWithNormals = false
        public var backfaceCulling = true

        public static var `default`: Self {
            .init()
        }
    }

    struct Fragment {
        var modelSpaceVertices: [SIMD3<Float>]
        var clipSpaceVertices: [SIMD4<Float>]
        var clipSpaceMin: SIMD3<Float>
        var modelSpaceNormal: SIMD3<Float>

        var stroke: (GraphicsContext.Shading, StrokeStyle)?
        var fill: (GraphicsContext.Shading, FillStyle)?

        init(vertices: [SIMD3<Float>], projection: Projection3D, stroke: (GraphicsContext.Shading, StrokeStyle)?, fill: (GraphicsContext.Shading, FillStyle)?) {
            modelSpaceVertices = vertices
            let transform = projection.clipTransform * projection.projectionTransform * projection.viewTransform
            clipSpaceVertices = modelSpaceVertices.map {
                transform * SIMD4<Float>($0, 1.0)
            }

            clipSpaceMin = clipSpaceVertices.reduce(into: [.infinity, .infinity, .infinity]) { result, vertex in
                result = [min(result.x, vertex.x), min(result.y, vertex.y), min(result.z, vertex.z)]
            }

            let a = modelSpaceVertices[0]
            let b = modelSpaceVertices[1]
            let c = modelSpaceVertices[2]
            modelSpaceNormal = simd_normalize(simd_cross(b - a, c - a))

            self.stroke = stroke
            self.fill = fill
        }
    }

    public var graphicsContext: GraphicsContext3D
    var fragments: [Fragment] = []
    public var options: Options

    public init(graphicsContext: GraphicsContext3D, options: Options = .default) {
        self.graphicsContext = graphicsContext
        self.options = options
    }

    public mutating func stroke(polygon: [SIMD3<Float>], with shading: GraphicsContext.Shading, style: StrokeStyle = .init()) {
        fragments.append(Fragment(vertices: polygon, projection: graphicsContext.projection, stroke: (shading, style), fill: nil))
    }

    public mutating func fill(polygon: [SIMD3<Float>], with shading: GraphicsContext.Shading, style: FillStyle = .init()) {
        fragments.append(Fragment(vertices: polygon, projection: graphicsContext.projection, stroke: nil, fill: (shading, style)))
    }

    public mutating func rasterize() {
        let fragments = fragments
            .filter {
                // TODO: Do actual frustrum culling.
                $0.clipSpaceMin.z <= 0
            }
            .sorted { lhs, rhs in
                compare(lhs.clipSpaceMin.reverseTuple, rhs.clipSpaceMin.reverseTuple) == .orderedAscending
            }
        for fragment in fragments {
            let viewPosition = graphicsContext.projection.viewTransform.inverse.translation
            let viewSpaceNormal = (graphicsContext.projection.viewTransform * SIMD4(fragment.modelSpaceNormal, 1.0)).xyz
            let backFacing = simd_dot(fragment.modelSpaceVertices[0] - viewPosition, fragment.modelSpaceNormal) >= 0
            if options.backfaceCulling && backFacing {
                continue
            }
            let lines = fragment.clipSpaceVertices.map {
                let screenSpace = SIMD3($0.x, $0.y, $0.z) / $0.w
                return CGPoint(x: Double(screenSpace.x), y: Double(screenSpace.y))
            }

            let path = Path { path in
                path.addLines(lines)
                path.closeSubpath()
            }

            if let fill = fragment.fill {
                let shading = !options.shadeFragmentsWithNormals ? fill.0 : .color(viewSpaceNormal)
                graphicsContext.graphicsContext2D.fill(path, with: shading, style: fill.1)
            }
            if let stroke = fragment.stroke {
                let shading = !options.shadeFragmentsWithNormals ? stroke.0 : .color(viewSpaceNormal)
                graphicsContext.graphicsContext2D.stroke(path, with: shading, style: stroke.1)
            }

            if options.drawNormals {
                let center = (fragment.modelSpaceVertices.reduce(.zero, +) / Float(fragment.modelSpaceVertices.count))
                let path = Path3D { path in
                    path.move(to: center)
                    path.addLine(to: center + fragment.modelSpaceNormal * Float(options.normalsLength))
                }
                graphicsContext.stroke(path: path, with: backFacing ? .color(.red) : .color(.blue))
            }
        }
    }
}

// TODO: Move
func compare<C>(_ lhs: C, _ rhs: C) -> ComparisonResult where C: Comparable {
    if lhs == rhs {
        return .orderedSame
    }
    else if lhs < rhs {
        return .orderedAscending
    }
    else {
        return .orderedDescending
    }
}

// TODO: Move
func compare<C>(_ lhs: (C, C), _ rhs: (C, C)) -> ComparisonResult where C: Comparable {
    let r = compare(lhs.0, rhs.0)
    if r == .orderedSame {
        return compare(lhs.1, rhs.1)
    }
    else {
        return r
    }
}

// TODO: Move
func compare<C>(_ lhs: (C, C, C), _ rhs: (C, C, C)) -> ComparisonResult where C: Comparable {
    let r = compare((lhs.0, lhs.1), (rhs.0, rhs.1))
    if r == .orderedSame {
        return compare(lhs.2, rhs.2)
    }
    else {
        return r
    }
}

// TODO: Move
public extension SIMD3 {
    var tuple: (Scalar, Scalar, Scalar) {
        (x, y, z)
    }

    var reverseTuple: (Scalar, Scalar, Scalar) {
        (z, y, x)
    }
}

public extension GraphicsContext3D {
    func rasterize(options: Rasterizer.Options = .default, content: (inout Rasterizer) -> Void) {
        var rasterizer = Rasterizer(graphicsContext: self, options: options)
        content(&rasterizer)
        rasterizer.rasterize()

    }
}
