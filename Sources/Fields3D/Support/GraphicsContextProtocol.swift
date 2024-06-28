import SwiftUI

protocol GraphicsContextProtocol {
    var opacity: Double { get set }
    var blendMode: GraphicsContext.BlendMode { get set }
    var environment: EnvironmentValues { get }
    var transform: CGAffineTransform { get set }

    var clipBoundingRect: CGRect { get }

    mutating func clip(to path: Path, style: FillStyle, options: GraphicsContext.ClipOptions)
    mutating func clipToLayer(opacity: Double, options: GraphicsContext.ClipOptions, content: (inout GraphicsContext) throws -> Void) rethrows

    mutating func addFilter(_ filter: GraphicsContext.Filter, options: GraphicsContext.FilterOptions)

    func resolve(_ shading: GraphicsContext.Shading) -> GraphicsContext.Shading
    func drawLayer(content: (inout GraphicsContext) throws -> Void) rethrows
    func fill(_ path: Path, with shading: GraphicsContext.Shading, style: FillStyle)
    func stroke(_ path: Path, with shading: GraphicsContext.Shading, style: StrokeStyle)
}

extension GraphicsContextProtocol {
    func stroke(_ path: Path, with shading: GraphicsContext.Shading) {
        stroke(path, with: shading, style: .init())
    }
}

extension GraphicsContext: GraphicsContextProtocol {
}
