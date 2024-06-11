import SwiftUI

protocol ShadingProtocol {
    static func color(_ color: Color) -> Self
}

protocol GraphicsContextProtocol {
    associatedtype Shading: ShadingProtocol

    typealias BlendMode = GraphicsContext.BlendMode
    var opacity: Double { get set }
    var blendMode: BlendMode { get set }
    var environment: EnvironmentValues { get }
    var transform: CGAffineTransform { get set }
    mutating func scaleBy(x: CGFloat, y: CGFloat)
    mutating func translateBy(x: CGFloat, y: CGFloat)
    mutating func rotate(by angle: Angle)
    mutating func concatenate(_ matrix: CGAffineTransform)
    typealias ClipOptions = GraphicsContext.ClipOptions
    var clipBoundingRect: CGRect { get }
    mutating func clip(to path: Path, style: FillStyle, options: ClipOptions)
    mutating func clipToLayer(opacity: Double, options: ClipOptions, content: (inout Self) throws -> Void) rethrows
    typealias Filter = GraphicsContext.Filter
    typealias ShadowOptions = GraphicsContext.ShadowOptions
    typealias BlurOptions = GraphicsContext.BlurOptions
    typealias FilterOptions = GraphicsContext.FilterOptions
//    mutating func addFilter(_ filter: Filter, options: FilterOptions)
    typealias GradientOptions = GraphicsContext.GradientOptions
//    func resolve(_ shading: Shading) -> Shading
    func drawLayer(content: (inout Self) throws -> Void) rethrows
    func fill(_ path: Path, with shading: Shading, style: FillStyle)
    func stroke(_ path: Path, with shading: Shading, style: StrokeStyle)
    func stroke(_ path: Path, with shading: Shading, lineWidth: CGFloat)
    typealias ResolvedImage = GraphicsContext.ResolvedImage
//    func resolve(_ image: Image) -> ResolvedImage
//    func draw(_ image: ResolvedImage, in rect: CGRect, style: FillStyle)
//    func draw(_ image: ResolvedImage, at point: CGPoint, anchor: UnitPoint)
    @MainActor func draw(_ image: Image, in rect: CGRect, style: FillStyle)
    @MainActor func draw(_ image: Image, at point: CGPoint, anchor: UnitPoint)
    typealias ResolvedText = GraphicsContext.ResolvedText
//    func resolve(_ text: Text) -> ResolvedText
//    func draw(_ text: ResolvedText, in rect: CGRect)
//    func draw(_ text: ResolvedText, at point: CGPoint, anchor: UnitPoint)
    @MainActor func draw(_ text: Text, in rect: CGRect)
//    func draw(_ text: Text, at point: CGPoint, anchor: UnitPoint)
    typealias ResolvedSymbol = GraphicsContext.ResolvedSymbol
//    func resolveSymbol<ID>(id: ID) -> GraphicsContext.ResolvedSymbol? where ID : Hashable
//    func draw(_ symbol: GraphicsContext.ResolvedSymbol, in rect: CGRect)
//    func draw(_ symbol: GraphicsContext.ResolvedSymbol, at point: CGPoint, anchor: UnitPoint)
//
    func withCGContext(content: (CGContext) throws -> Void) rethrows
}

extension GraphicsContextProtocol {
    mutating func clip(to path: Path, style: FillStyle = FillStyle(), options: ClipOptions = ClipOptions()) {
        clip(to: path, style: style, options: options)
    }

    mutating func clipToLayer(opacity: Double = 1, options: ClipOptions = ClipOptions(), content: (inout Self) throws -> Void) rethrows {
        try clipToLayer(opacity: opacity, options: options, content: content)
    }

//    mutating func addFilter(_ filter: Filter, options: FilterOptions = FilterOptions()) {
//    }

    func fill(_ path: Path, with shading: Shading, style: FillStyle = FillStyle()) {
        fill(path, with: shading, style: style)
    }

    func stroke(_ path: Path, with shading: Shading, lineWidth: CGFloat = 1) {
        stroke(path, with: shading, style: .init(lineWidth: lineWidth))
    }

//    func draw(_ image: ResolvedImage, in rect: CGRect, style: FillStyle = FillStyle()) {
//    }
//
//    func draw(_ image: ResolvedImage, at point: CGPoint, anchor: UnitPoint = .center) {
//    }
//
    @MainActor func draw(_ image: Image, in rect: CGRect, style: FillStyle = FillStyle()) {
        draw(image, in: rect, style: style)
    }

    @MainActor func draw(_ image: Image, at point: CGPoint, anchor: UnitPoint = .center) {
        draw(image, at: point, anchor: anchor)
    }
//
//    func draw(_ text: ResolvedText, at point: CGPoint, anchor: UnitPoint = .center) {
//    }
//
//    func draw(_ text: Text, at point: CGPoint, anchor: UnitPoint = .center) {
//    }
//
//    func draw(_ symbol: GraphicsContext.ResolvedSymbol, at point: CGPoint, anchor: UnitPoint) {
//    }
}

extension GraphicsContextProtocol {
    mutating func scaleBy(x: CGFloat, y: CGFloat) {
        transform = transform.concatenating(.init(scaleX: x, y: y))
    }

    mutating func translateBy(x: CGFloat, y: CGFloat) {
        transform = transform.concatenating(.init(translationX: x, y: y))
    }

    mutating func rotate(by angle: Angle) {
        transform = transform.concatenating(.init(rotationAngle: angle.radians))
    }

    mutating func concatenate(_ matrix: CGAffineTransform) {
        transform = transform.concatenating(matrix)
    }
}

// MARK: -

extension GraphicsContext: GraphicsContextProtocol {
}

extension GraphicsContext.Shading: ShadingProtocol {
}
