import SwiftUI

public enum DraggableParameterBehavior {
    case clamping
    case wrapping
}

public enum DraggableParameterAxis {
    case horizontal
    case vertical
}

public extension View {
    func draggableParameter(_ parameter: Binding<Double>, axis: DraggableParameterAxis, range: ClosedRange<Double>? = nil, scale: Double, behavior: DraggableParameterBehavior) -> some View {
        self.modifier(DraggableParamaterViewModifier(parameter: parameter, axis: axis, range: range, scale: scale, behavior: behavior))
    }
}

public struct DraggableParamaterViewModifier: ViewModifier {
    @Binding
    var parameter: Double
    var axis: DraggableParameterAxis
    var range: ClosedRange<Double>?
    var scale: Double
    var behavior: DraggableParameterBehavior

    @State
    var initialValue: Double?

    public init(parameter: Binding<Double>, axis: DraggableParameterAxis, range: ClosedRange<Double>? = nil, scale: Double, behavior: DraggableParameterBehavior) {
        self._parameter = parameter
        self.axis = axis
        self.range = range
        self.scale = scale
        self.behavior = behavior
        self.initialValue = initialValue
    }

    public func body(content: Content) -> some View {
        content.simultaneousGesture(dragGesture)
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if initialValue == nil {
                    initialValue = parameter
                }

                let input: Double
                switch axis {
                case .horizontal:
                    input = value.translation.width
                case .vertical:
                    input = value.translation.height
                }
                var newValue = initialValue.unsafelyUnwrapped + input * scale
                if let range {
                switch behavior {
                case .clamping:
                    newValue = newValue.clamped(to: range)
                case .wrapping:
                    newValue = newValue.wrapped(to: range)
                    }
                }
                parameter = newValue
            }
            .onEnded { _ in
                initialValue = nil
            }
    }
}
