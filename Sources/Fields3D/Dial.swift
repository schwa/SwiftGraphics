import SwiftUI
import CoreGraphicsSupport

struct Dial: View {

    enum InteractionShape {
        case radial
        case linear
    }

    @Binding
    var value: Double

    var range: ClosedRange<Double>

    var interactionShape: InteractionShape = .linear

    @Environment(\.dialStyle)
    var dialStyle

    @State
    var inDrag = false

    @State
    var size: CGSize = .zero

    var body: some View {
        dialStyle.makeBody_(configuration: .init(value: value, range: range, interactionShape: interactionShape, inDrag: inDrag))
        .geometrySize($size)
        .gesture(
            SpatialTapGesture()
            .onEnded { gesture in
                self.value = value(for: gesture.location)
            }
        )
        .gesture(
            DragGesture()
            .onChanged { gesture in
                self.value = value(for: gesture.location)
            }
        )
    }

    func value(for point: CGPoint) -> Double {
        switch interactionShape {
        case .radial:
            let center = CGPoint(size) / 2
            let vector = CGVector(dx: point.x - center.x, dy: point.y - center.y)
            let newAngle = (Angle(radians: atan2(vector.dy, vector.dx)) + .degrees(90)).degrees
            return (newAngle < 0 ? newAngle + 360 : newAngle) / 360 * (range.upperBound - range.lowerBound) + range.lowerBound
        case .linear:
            if size.width > size.height {
                return clamp(point.x, in: 0...size.width) / size.width * (range.upperBound - range.lowerBound) + range.lowerBound
            }
            else {
                return clamp(point.y, in: 0...size.height) / size.height * (range.upperBound - range.lowerBound) + range.lowerBound
            }
        }
    }
}

struct DialStyleConfiguration {
    var value: Double
    var range: ClosedRange<Double>
    var interactionShape: Dial.InteractionShape
    var inDrag: Bool
}

@MainActor
protocol DialStyle {
    associatedtype Body: View
    typealias Configuration = DialStyleConfiguration
    @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

extension DialStyle {
    func makeBody_(configuration: Configuration) -> AnyView {
        AnyView( makeBody(configuration: configuration) )
    }
}

struct DefaulDialStyle: DialStyle {
    func makeBody(configuration: Configuration) -> some View {
        Canvas { context, size in
            let frame = CGRect(origin: .zero, size: size).insetBy(dx: 5, dy: 5)
            let center = frame.midXMidY
            let radius = min(frame.size.width, frame.size.height) / 2

            let dialPath = Path { path in
                path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
            }
            context.stroke(dialPath, with: .color(.gray.opacity(0.2)), lineWidth: 2)

            let value = (configuration.value - configuration.range.lowerBound) / (configuration.range.upperBound - configuration.range.lowerBound)

            let angle = Angle.degrees(360 * value)

            let activePath = Path { path in
                path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: angle - .degrees(90), clockwise: false)
            }
            context.stroke(activePath, with: .color(.blue), style: StrokeStyle(lineWidth: 2, lineCap: .round))

            let knobPosition = CGPoint(x: center.x + radius * CGFloat(cos(angle.radians - .pi/2)), y: center.y + radius * CGFloat(sin(angle.radians - .pi/2)))
            context.fill(Circle().path(in: CGRect(center: knobPosition, radius: 4)), with: .color(.blue))
        }
        .contentShape(Circle())
        .frame(width: 32, height: 32)
    }
}

struct DialStyleKey: EnvironmentKey {
    // TODO: FIXME
    nonisolated(unsafe) static let defaultValue: any DialStyle = DefaulDialStyle()
}

extension EnvironmentValues {
    var dialStyle: (any DialStyle) {
        get {
            self[DialStyleKey.self]
        }
        set {
            self[DialStyleKey.self] = newValue
        }
    }
}

extension View {
    func dialStyle(value: some DialStyle) -> some View {
        self.environment(\.dialStyle, value)
    }
}

#Preview {
    @Previewable @State var value = 0.0
    Form {
        HStack {
            TextField("Value", value: $value, format: .number)
            Dial(value: $value, range: 0...100)
        }
    }
    .padding()
}
