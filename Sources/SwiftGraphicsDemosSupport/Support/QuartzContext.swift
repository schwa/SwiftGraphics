import SwiftUI

// TODO: This @preconcurrency is weird.
struct QuartzContext: GraphicsContextProtocol {
    struct Shading {
        enum Value {
            case color(Color)
        }

        var value: Value
    }

    var cgContext: CGContext
    var size: CGSize

    var blendMode: Self.BlendMode {
        didSet {
            // TODO: this hopes that CGBlendMode == GraphicsCOntext.BlendMode
            cgContext.setBlendMode(CGBlendMode(rawValue: blendMode.rawValue)!)
        }
    }

    var opacity: Double {
        didSet {
            cgContext.setAlpha(opacity)
        }
    }

    var transform: CGAffineTransform {
        didSet {
            // TODO: There has to be a better way
            let ctm = cgContext.ctm
            cgContext.concatenate(ctm.inverted())
            cgContext.concatenate(transform)
        }
    }

    var environment: EnvironmentValues

    init(cgContext: CGContext, size: CGSize, environment: EnvironmentValues = .init()) {
        self.cgContext = cgContext
        self.size = size
        self.environment = environment
        blendMode = .normal
        opacity = 1.0
        transform = .identity
    }

    func fill(_ path: Path, with shading: Shading, style: FillStyle) {
        cgContext.addPath(path.cgPath)
        switch shading.value {
        case .color(let color):
            let color = color.resolve(in: environment).cgColor
            cgContext.setFillColor(color)
        }
        cgContext.fillPath() // TODO: rest of fill style
    }

    func stroke(_ path: Path, with shading: Shading, style: StrokeStyle) {
        cgContext.addPath(path.cgPath)
        switch shading.value {
        case .color(let color):
            let color = color.resolve(in: environment).cgColor
            cgContext.setStrokeColor(color)
        }
        // TODO: Avoid setting all this per draw?
        cgContext.setLineCap(style.lineCap)
        cgContext.setLineDash(phase: style.dashPhase, lengths: style.dash)
        cgContext.setLineJoin(style.lineJoin)
        cgContext.setLineWidth(style.lineWidth)
        cgContext.setMiterLimit(style.miterLimit)
        cgContext.strokePath()
    }

    var clipBoundingRect: CGRect {
        cgContext.boundingBoxOfClipPath
    }

    mutating func clip(to path: Path, style: FillStyle, options: ClipOptions) {
        // TODO: style
        if options.contains(.inverse) {
            let contextPath = Path(CGRect(origin: .zero, size: size))
            cgContext.addPath(contextPath.subtracting(path).cgPath)
        }
        else {
            cgContext.addPath(path.cgPath)
        }
        cgContext.clip()
    }

    mutating func clipToLayer(opacity: Double, options: ClipOptions, content: (inout Self) throws -> Void) rethrows {
        fatalError("Unimplemented") // TODO: Unimplemented
    }

    func drawLayer(content: (inout Self) throws -> Void) rethrows {
        // TODO: Untested
        cgContext.saveGState()
        defer {
            cgContext.restoreGState()
        }
        var copy = self
        try content(&copy)
    }

    @MainActor
    func draw(_ image: Image, in rect: CGRect, style: FillStyle) {
        let image = image.resizable().frame(width: rect.width, height: rect.height)
        let renderer = ImageRenderer(content: image)
        renderer.scale = 4 // TODO: Picked at random
        guard let image = renderer.cgImage else {
            fatalError("Could not create cgImage.")
        }
        cgContext.draw(image, in: rect)
    }

    @MainActor
    func draw(_ image: Image, at point: CGPoint, anchor: UnitPoint) {
        let image = image.resizable()
        let renderer = ImageRenderer(content: image)
        renderer.scale = 4 // TODO: Picked at random
        guard let image = renderer.cgImage else {
            fatalError("Could not create cgImage.")
        }
        let rect = CGRect(x: point.x - image.size.width, y: point.y - image.size.height, width: image.size.width, height: image.size.height)
        cgContext.draw(image, in: rect)
    }

    @MainActor
    func draw(_ text: Text, in rect: CGRect) {
        let image = text.frame(width: rect.width, height: rect.height)
        let renderer = ImageRenderer(content: image)
        renderer.scale = 4 // TODO: Picked at random
        guard let image = renderer.cgImage else {
            fatalError("Could not create cgImage.")
        }

        // TODO: Flip
        cgContext.draw(image, in: rect)
    }

    func withCGContext(content: (CGContext) throws -> Void) rethrows {
        try content(cgContext)
    }
}

extension QuartzContext.Shading: ShadingProtocol {
    static func color(_ color: Color) -> Self {
        .init(value: .color(color))
    }
}

// MARK: -

struct QuartzCanvas: View {
    let renderer: (inout QuartzContext, CGSize) -> Void

    init(renderer: @escaping (inout QuartzContext, CGSize) -> Void) {
        self.renderer = renderer
    }

    var body: some View {
        Canvas { context, size in
            context.withCGContext { cgContext in
                var quartzContext = QuartzContext(cgContext: cgContext, size: size, environment: context.environment)
                renderer(&quartzContext, size)
            }
        }
    }
}
