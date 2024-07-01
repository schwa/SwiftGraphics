import SwiftUI
import CoreGraphicsSupport

public struct Wheel: View {
    @Binding var value: Double

    @State private var lastDragValue: Double = 0.0


    @State var size: CGSize = .zero

    public init(value: Binding<Double>) {
        self._value = value
    }

    public var body: some View {
        WheelContentView(value: value)
            .geometrySize($size)
            .gesture(DragGesture().onChanged { drag in
                value += (drag.translation.width - lastDragValue) / size.width
                lastDragValue = drag.translation.width
            }.onEnded { drag in
                withAnimation(.easeOut) {
                    print(drag.predictedEndTranslation.width)
                    value += (drag.predictedEndTranslation.width - lastDragValue) / size.width
                }
                lastDragValue = 0.0
            })
            .gesture(LongPressGesture().onEnded { _ in
                withAnimation {
                    value = 0
                }
            })
    }

    struct WheelContentView: View, @preconcurrency Animatable {
        @Environment(\.wheelStyle)
        var wheelStyle
        var value: Double
        var body: some View {
            wheelStyle.makeBody_(configuration: .init(value: value, inDrag: false))
        }
        var animatableData: Double {
            get {
                value
            }
            set {
                value = newValue
            }
        }
    }
}

// MARK: -

struct WheelStyleConfiguration {
    var value: Double
    var inDrag: Bool
}

@MainActor
protocol WheelStyle {
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
        .contentShape(Rectangle())
        .border(.gray.opacity(0.8))
        .frame(width: 60, height: 10)
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

struct WheelStyleKey: EnvironmentKey {
    // TODO: FIXME
    nonisolated(unsafe) static let defaultValue: any WheelStyle = DefaultWheelStyle()
}

extension EnvironmentValues {
    var wheelStyle: (any WheelStyle) {
        get {
            self[WheelStyleKey.self]
        }
        set {
            self[WheelStyleKey.self] = newValue
        }
    }
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
        Wheel(value: $value)
        Spacer()
        Text("\(value)")
    }
    .padding()
}
