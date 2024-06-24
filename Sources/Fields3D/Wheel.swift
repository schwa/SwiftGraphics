import SwiftUI
import CoreGraphicsSupport
import SwiftGraphicsSupport

public struct Wheel <Label>: View where Label: View {
    @Binding
    var value: Double

    var rate: Double

    var label: Label

    @State
    private var lastDragValue: Double = 0.0

    @State
    private var size: CGSize = .zero

    @Environment(\.wheelStyle)
    var wheelStyle

    public init(value: Binding<Double>, rate: Double = 1, label: () -> Label) {
        self._value = value
        self.rate = rate
        self.label = label()
    }

    public var body: some View {
        AnimatableValueView(value: value) {
            wheelStyle.makeBody_(configuration: .init(label: AnyView(label), value: $0, inDrag: false))
        }
        .focusable(interactions: .activate)
        .geometrySize($size)
        .gesture(drag())
        .gesture(LongPressGesture(minimumDuration: 2).onEnded { _ in
            withAnimation {
                value = 0
            }
        })
#if os(macOS)
            .onMoveCommand { direction in

                switch direction {
                case .right, .up:
                    withAnimation {
                        value += 1 * rate
                    }
                case .left, .down:
                    withAnimation {
                        value -= 1 * rate
                    }
                default:
                    break

                }
            }
#endif


//        .onKeyPress(.rightArrow, phases: .all) { _ in
//            withAnimation {
//                value += 1 * rate
//            }
//            return .handled
//        }
//        .onKeyPress(.leftArrow, phases: [.down, .repeat]) { _ in
//            withAnimation {
//                value -= 1 * rate
//            }
//            return .handled
//        }
    }

    func drag() -> some Gesture {
        DragGesture()
        .onChanged { drag in
            value += (drag.translation.width - lastDragValue) / size.width * rate
            lastDragValue = drag.translation.width
        }
        .onEnded { drag in
            print(drag.predictedEndTranslation)
            if drag.predictedEndTranslation.width > 200 {
                withAnimation(.easeOut) {
                    value += (drag.predictedEndTranslation.width - lastDragValue) / size.width * rate
                }
            }
            lastDragValue = 0.0
        }
    }

}

extension Wheel where Label == EmptyView {
    public init(value: Binding<Double>, rate: Double = 1) {
        self.init(value: value, rate: rate, label: { EmptyView() })
    }
}

extension Wheel where Label == Text {
    public init(label: String, value: Binding<Double>, rate: Double = 1) {
        self.init(value: value, rate: rate, label: { Text(label) })
    }
}

// MARK: -

struct WheelStyleConfiguration {
    var label: AnyView
    var value: Double
    var inDrag: Bool
}

@MainActor
protocol WheelStyle: Sendable {
    associatedtype Body: View
    typealias Configuration = WheelStyleConfiguration
    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

extension WheelStyle {
    func makeBody_(configuration: Configuration) -> AnyView {
        AnyView( makeBody(configuration: configuration) )
    }
}

func wrap(_ value: Double, within range: ClosedRange<Double>) -> Double {
    let size = range.upperBound - range.lowerBound
    let normalized = value - range.lowerBound
    return (normalized.truncatingRemainder(dividingBy: size) + size).truncatingRemainder(dividingBy: size) + range.lowerBound
}

func wrap(_ point: CGPoint, within rect: CGRect) -> CGPoint {
    CGPoint(
        x: wrap(point.x, within: rect.minX ... rect.maxX),
        y: wrap(point.y, within: rect.minY ... rect.maxY)
    )
}

struct DefaultWheelStyle: WheelStyle {

    func makeBody(configuration: Configuration) -> some View {
        WheelStyleView(configuration: configuration)
    }

    struct WheelStyleView: View {
        var configuration: Configuration

        var body: some View {
            HStack(alignment: .center, spacing: 2) {
                configuration.label
                Canvas { context, size in
                    let frame = CGRect(origin: .zero, size: size)
                    let offset = CGPoint(
                        x: (configuration.value * frame.size.width),
                        y: 0
                    )
                    let tickSpacing = 4.0
                    let path = Path { path in
                        let center = CGPoint(x: frame.midX, y: frame.midX)
                        for x in stride(from: -frame.width, to: frame.width, by: tickSpacing) {
                            let point = wrap(offset + CGPoint(x: x, y: 0) + center, within: frame)
                            path.move(to: point + CGPoint(x: 0, y: -frame.width / 2))
                            path.addLine(to: point + CGPoint(x: 0, y: frame.width / 2))
                        }
                    }
                    context.stroke(path, with: .color(.gray.opacity(0.4)), lineWidth: 2)
                }
                .border(.gray.opacity(0.8))
                .contentShape(Rectangle())
                .frame(width: 60, height: 12)
            }

        }
    }
}

func sign(_ v: Double) -> Double {
    if v < 0 {
        return -1
    }
    else if v == 0 {
        return 0
    }
    else {
        return 1
    }
}

extension EnvironmentValues {
    @Entry
    var wheelStyle: any WheelStyle = DefaultWheelStyle()
}

extension View {
    func wheelStyle(_ value: some WheelStyle) -> some View {
        self.environment(\.wheelStyle, value)
    }
}

// MARK: -

#Preview {
    @Previewable @State var value = 0.0

    VStack {
        Wheel(value: $value, rate: 360)
        Button("Boing") {
            withAnimation {
                value += Double.random(in: 0...1000)
            }
        }
    }
    .padding()
}
