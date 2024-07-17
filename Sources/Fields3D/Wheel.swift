import BaseSupport
import CoreGraphicsSupport
import SwiftUI
import SwiftUISupport

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
        increment()
        case .left, .down:
        decrement()
        default:
        break
        }
        }
        #endif
        //        .accessibilityLabel("xxx")
        .accessibilityValue(Text("\(value.formatted())"))
        .accessibilityAddTraits(.allowsDirectInteraction)
        .accessibilityElement(children: .ignore)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                increment()
            case .decrement:
                decrement()
            @unknown default:
                break
            }
        }
    }

    func drag() -> some Gesture {
        DragGesture()
            .onChanged { drag in
                value += (drag.translation.width - lastDragValue) / size.width * rate
                lastDragValue = drag.translation.width
            }
            .onEnded { drag in
                if drag.predictedEndTranslation.width > 200 {
                    withAnimation(.easeOut) {
                        value += (drag.predictedEndTranslation.width - lastDragValue) / size.width * rate
                    }
                }
                lastDragValue = 0.0
            }
    }

    func increment() {
        withAnimation {
            value += 1 * rate
        }
    }

    func decrement() {
        withAnimation {
            value -= 1 * rate
        }
    }
}

public extension Wheel where Label == EmptyView {
    init(value: Binding<Double>, rate: Double = 1) {
        self.init(value: value, rate: rate) { EmptyView() }
    }
}

public extension Wheel where Label == Text {
    init(label: String, value: Binding<Double>, rate: Double = 1) {
        self.init(value: value, rate: rate) { Text(label) }
    }
}

// MARK: -

public struct WheelStyleConfiguration {
    public var label: AnyView
    public var value: Double
    public var inDrag: Bool
}

@MainActor
public protocol WheelStyle: Sendable {
    associatedtype Body: View
    typealias Configuration = WheelStyleConfiguration
    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

internal extension WheelStyle {
    func makeBody_(configuration: Configuration) -> AnyView {
        AnyView( makeBody(configuration: configuration) )
    }
}

public struct DefaultWheelStyle: WheelStyle {
    public func makeBody(configuration: Configuration) -> some View {
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
                            let point = wrap(offset + CGPoint(x: x, y: 0) + center, to: frame)
                            path.move(to: point + CGPoint(x: 0, y: -frame.width / 2))
                            path.addLine(to: point + CGPoint(x: 0, y: frame.width / 2))
                        }
                    }
                    context.stroke(path, with: .color(.accentColor.opacity(0.4)), lineWidth: 2)
                }
                .border(.gray.opacity(0.8))
                .contentShape(Rectangle())
                .frame(width: 60, height: 12)
            }
        }
    }
}

public extension EnvironmentValues {
    @Entry
    var wheelStyle: any WheelStyle = DefaultWheelStyle()
}

public extension View {
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
