import CoreGraphicsSupport
import SwiftUI

struct Handle: View {
    @Binding
    var location: CGPoint

    var coordinateSpace: CoordinateSpace

    var constraining: (_ current: CGPoint, _ suggested: CGPoint) -> CGPoint

    @Environment(\.handleStyle)
    var style

    @State
    private var isPressed = false

    @State
    private var dragDelta: CGPoint?

    init(_ location: Binding<CGPoint>, coordinateSpace: CoordinateSpace = .local, constraining: @escaping (_ current: CGPoint, _ suggested: CGPoint) -> CGPoint = { $1 }) {
        _location = location
        self.coordinateSpace = coordinateSpace
        self.constraining = constraining
    }

    var body: some View {
        AnyView(style.makeBody(configuration: .init(isPressed: isPressed)))
            .position(location)
            .gesture(drag)
    }

    var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: coordinateSpace)
            .onChanged { value in
                isPressed = true
                if dragDelta == nil {
                    dragDelta = value.location - location
                }
                location = constraining(location, value.location - dragDelta!)
            }
            .onEnded { _ in
                isPressed = false
                dragDelta = nil
            }
    }
}

struct HandleConfiguration {
    let isPressed: Bool
}

protocol HandleStyle: Sendable {
    associatedtype Body: View
    typealias Configuration = HandleConfiguration
    @ViewBuilder func makeBody(configuration: Configuration) -> Self.Body
}

struct SimpleHandleStyle: HandleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Circle()
            .foregroundColor(configuration.isPressed ? .accentColor : nil)
            .frame(width: 8, height: 8)
            .padding(2)
            .background(Color.clear)
            .contentShape(Circle())
    }
}

struct HandleStyleKey: EnvironmentKey {
    static let defaultValue: any HandleStyle = SimpleHandleStyle()
}

extension EnvironmentValues {
    var handleStyle: any HandleStyle {
        get {
            self[HandleStyleKey.self]
        }
        set {
            self[HandleStyleKey.self] = newValue
        }
    }
}

extension View {
    func handleStyle(_ style: some HandleStyle) -> some View {
        environment(\.handleStyle, style)
    }
}
