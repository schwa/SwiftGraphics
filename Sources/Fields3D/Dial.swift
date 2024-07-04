import CoreGraphicsSupport
import SwiftUI
import SwiftUISupport

// TODO: Bug - drag does not consider center of Canvas to be center of drag if the view has a label.

public struct Dial <Label>: View where Label: View {
    @Binding
    var value: Double

    var range: ClosedRange<Double>
    var stepRate: Double

    var label: Label

    @Environment(\.dialStyle)
    var dialStyle

    @State
    private var inDrag = false

    @State
    private var size: CGSize = .zero

    let dragCoordinateSpace = NamedCoordinateSpace.named("DragGestureCoordinateSpace")

    public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, stepRate: Double = 0.1, @ViewBuilder label: () -> Label) {
        self._value = value
        self.range = range
        self.stepRate = stepRate
        self.label = label()
    }

    public var body: some View {
        AnimatableValueView(value: value) { value in
            dialStyle.makeBody_(configuration: .init(value: value, range: range, label: AnyView(label), inDrag: inDrag, dragCoordinateSpace: dragCoordinateSpace))
        }
        .focusable(interactions: .activate)
        .geometrySize($size)
        .gesture(
            SpatialTapGesture()
                .onChanged { _ in
                    inDrag = true
                }
                .onEnded { gesture in
                    value = value(for: gesture.location)
                    inDrag = false
                }
        )
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: dragCoordinateSpace)
                .onChanged { gesture in
                    inDrag = true
                    value = value(for: gesture.location)
                }
                .onEnded { _ in
                    inDrag = false
                }
        )
        #if os(macOS)
        .onMoveCommand { direction in
        switch direction {
        case .right, .up:
        increment()
        case .left, .down:
        decrement()
        default:
        break
        }
        }
        #endif
        .accessibilityRepresentation {
            Slider(value: $value, in: range) { label }
        }
    }

    func value(for point: CGPoint) -> Double {
        let center = CGPoint(size) / 2
        let vector = CGVector(dx: point.x - center.x, dy: point.y - center.y)
        let newAngle = (Angle(radians: atan2(vector.dy, vector.dx)) + .degrees(90)).degrees
        let value = (newAngle < 0 ? newAngle + 360 : newAngle) / 360 * (range.upperBound - range.lowerBound) + range.lowerBound
        return value.wrapped(to: range)
    }

    func increment() {
        withAnimation {
            let delta = (range.upperBound - range.lowerBound) * stepRate
            value = (value + delta).clamped(to: range)
        }
    }

    func decrement() {
        withAnimation {
            let delta = (range.upperBound - range.lowerBound) * stepRate
            value = (value - delta).clamped(to: range)
        }
    }
}

// MARK: -

public extension Dial where Label == EmptyView {
    init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, stepRate: Double = 0.1) {
        self.init(value: value, in: range, stepRate: stepRate) {}
    }
}

public extension Dial where Label == Text {
    init(_ titleKey: LocalizedStringKey, value: Binding<Double>, in range: ClosedRange<Double> = 0...1, stepRate: Double = 0.1) {
        self.init(value: value, in: range, stepRate: stepRate) { Text(titleKey) }
    }
}

// MARK: -

public struct DialStyleConfiguration {
    public var value: Double
    public var range: ClosedRange<Double>
    public var label: AnyView
    public var inDrag: Bool
    public var dragCoordinateSpace: NamedCoordinateSpace
}

@MainActor
public protocol DialStyle: Sendable {
    associatedtype Body: View
    typealias Configuration = DialStyleConfiguration
    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

internal extension DialStyle {
    func makeBody_(configuration: Configuration) -> AnyView {
        AnyView( makeBody(configuration: configuration) )
    }
}

public extension EnvironmentValues {
    @Entry
    var dialStyle: any DialStyle = UnifiedDialStyle(styleType: .circular)
}

public extension View {
    func dialStyle(value: some DialStyle) -> some View {
        self.environment(\.dialStyle, value)
    }
}

// MARK: -

public struct UnifiedDialStyle: DialStyle {
    public enum StyleType: Sendable {
        case circular
        case slice
    }

    nonisolated
    public let styleType: StyleType

    public func makeBody(configuration: Configuration) -> some View {
        @Environment(\.controlSize)
        var controlSize

        VStack {
            let size = 32 * max(controlSize.ratio.x, controlSize.ratio.x)
            let lineWidth = 2.0
            let knobRadius = 4 * controlSize.ratio.y
            let inset = max(lineWidth / 2, styleType == .circular ? knobRadius + 0.5 : 0)

            let thumbFillColor: GraphicsContext.Shading = .color(!configuration.inDrag ? .white : .init(white: 0.95))
            let inactiveColor: GraphicsContext.Shading = .color(.gray.opacity(0.2))
            let activeColor: GraphicsContext.Shading = .color(.accentColor)

            Canvas { context, size in
                let frame = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
                let center = frame.midXMidY
                let radius = min(frame.size.width, frame.size.height) / 2
                let value = configuration.range.normalize(configuration.value)
                let angle = Angle.degrees(360 * value)

                switch styleType {
                case .circular:
                    let dialPath = Path { path in
                        path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                    }
                    context.stroke(dialPath, with: inactiveColor, lineWidth: lineWidth)
                    let activePath = Path { path in
                        path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: angle - .degrees(90), clockwise: false)
                    }
                    context.stroke(activePath, with: activeColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    let knobPosition = CGPoint(x: center.x + radius * CGFloat(cos(angle.radians - .pi / 2)), y: center.y + radius * CGFloat(sin(angle.radians - .pi / 2)))
                    context.fill(Path(ellipseIn: CGRect(center: knobPosition, radius: knobRadius)), with: thumbFillColor)
                    context.stroke(Path(ellipseIn: CGRect(center: knobPosition, radius: knobRadius)), with: inactiveColor)
                case .slice:
                    if value != 0 {
                        let dialPath = Path { path in
                            path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                        }
                        context.stroke(dialPath, with: inactiveColor, lineWidth: lineWidth)
                        let activePath = Path { path in
                            path.move(to: center)
                            path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: angle - .degrees(90), clockwise: false)
                            path.closeSubpath()
                        }
                        context.fill(activePath, with: activeColor)
                    } else {
                        let dialPath = Path { path in
                            path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                            path.move(to: CGPoint(x: center.x, y: center.y))
                            path.addLine(to: CGPoint(x: center.x, y: center.y - radius))
                        }
                        context.stroke(dialPath, with: inactiveColor, lineWidth: lineWidth)
                    }
                }
            }
            .coordinateSpace(configuration.dragCoordinateSpace)
            .contentShape(Circle())
            .frame(width: size, height: size)
            configuration.label
        }
    }
}

// MARK: -

#Preview {
    @Previewable @State var value = 0.0
    Form {
        VStack {
            TextField("Value", value: $value, format: .number)
                .frame(maxWidth: 120)
            Slider(value: $value, in: 0...100)
            Dial("\(value.formatted())", value: $value, in: 0...100)
                .dialStyle(value: UnifiedDialStyle(styleType: .slice))
                .controlSize(.regular)
        }
    }
    .padding()
}

extension ClosedRange where Bound: FloatingPoint {
    func normalize(_ value: Bound) -> Bound {
        (value - lowerBound) / (upperBound - lowerBound)
    }
}
