import BaseSupport
import Observation
import SwiftUI

struct ReplayableCanvas: View {
    let renderer: (inout ReplayableGraphicsContext, CGSize) -> Void

    @State
    private var maxEvent = 0.0

    @State
    private var replayableModel = ReplayableModel()

    var body: some View {
        Canvas { context, size in
            var replayableContext = replayableModel.makeContext()
            if replayableModel.events.isEmpty {
                renderer(&replayableContext, size)
            }
            replayableModel.replay(context: context, range: 0..<Int(maxEvent))
        }
        .overlay(alignment: .bottom) {
            Slider(value: $maxEvent, in: 0.0 ... Double(replayableModel.events.count))
                .frame(maxWidth: 320)
                .padding()
                .background(Color.black.opacity(0.2).cornerRadius(16))
                .padding()
        }
    }
}

@Observable
class ReplayableModel {
    typealias Event = ReplayableGraphicsContext.Event

    var events: [Event] = []

    func reset() {
        events = []
    }

    func record(event: Event) {
        events.append(event)
    }

    func makeContext() -> ReplayableGraphicsContext {
        ReplayableGraphicsContext(model: self)
    }

    func replay(context: some GraphicsContextProtocol2, range: Range<Int>? = nil) {
        let range = range ?? 0..<events.count
        for event in events[range] {
            switch event {
            case .fill(path: let path, let shading, style: let style):
                context.fill(path, with: shading, style: style)
            case .stroke(path: let path, let shading, style: let style):
                context.stroke(path, with: shading, style: style)
            }
        }
    }
}

struct ReplayableGraphicsContext: GraphicsContextProtocol2 {
    enum Event {
        case stroke(path: Path, GraphicsContext.Shading, style: StrokeStyle)
        case fill(path: Path, GraphicsContext.Shading, style: FillStyle)
    }
    var model: ReplayableModel

    // MARK: -

    var opacity: Double = 1.0
    var blendMode: GraphicsContext.BlendMode = .normal
    var environment: EnvironmentValues { .init() }
    var transform: CGAffineTransform = .identity

    var clipBoundingRect: CGRect {
        unimplemented()
    }

    mutating func clip(to path: Path, style: FillStyle, options: GraphicsContext.ClipOptions) {
        unimplemented()
    }

    mutating func clipToLayer(opacity: Double, options: GraphicsContext.ClipOptions, content: (inout GraphicsContext) throws -> Void) rethrows {
        unimplemented()
    }

    mutating func addFilter(_ filter: GraphicsContext.Filter, options: GraphicsContext.FilterOptions) {
        unimplemented()
    }

    func resolve(_ shading: GraphicsContext.Shading) -> GraphicsContext.Shading {
        unimplemented()
    }

    func drawLayer(content: (inout GraphicsContext) throws -> Void) rethrows {
        unimplemented()
    }

    func fill(_ path: Path, with shading: GraphicsContext.Shading, style: FillStyle) {
        model.events.append(.fill(path: path, shading, style: style))
    }

    func stroke(_ path: Path, with shading: GraphicsContext.Shading, style: StrokeStyle) {
        model.events.append(.stroke(path: path, shading, style: style))
    }
}
