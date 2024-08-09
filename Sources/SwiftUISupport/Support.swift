import Everything
import SwiftFormats
import SwiftUI

#if !os(tvOS)
public struct MyDisclosureGroupStyle: DisclosureGroupStyle {
    public init() {
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                configuration.label
            }
            .buttonStyle(.borderless)
            if configuration.isExpanded {
                configuration.content
            }
        }
        .padding(4)
    }
}

public struct SliderPopoverButton<Label, ValueLabel>: View where Label: View, ValueLabel: View {
    @Binding
    var value: Double

    var bounds: ClosedRange<Double>

    var label: Label
    var minimumValueLabel: ValueLabel
    var maximumValueLabel: ValueLabel
    var onEditingChanged: (Bool) -> Void

    @State
    private var isPresented = false

    public var body: some View {
        Button(systemImage: "slider.horizontal.2.square") {
            isPresented = true
        }
        .buttonStyle(.borderless)
        .tint(.accentColor)
        .popover(isPresented: $isPresented) {
            Slider(value: $value, in: bounds, label: { label }, minimumValueLabel: { minimumValueLabel }, maximumValueLabel: { maximumValueLabel }, onEditingChanged: onEditingChanged)
                .controlSize(.mini)
                .frame(minWidth: 100)
                .padding()
        }
    }

    init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0 ... 1, @ViewBuilder label: () -> Label, @ViewBuilder minimumValueLabel: () -> ValueLabel, @ViewBuilder maximumValueLabel: () -> ValueLabel, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
        _value = Binding<Double>(value)
        self.bounds = Double(bounds.lowerBound) ... Double(bounds.upperBound)
        self.label = label()
        self.minimumValueLabel = minimumValueLabel()
        self.maximumValueLabel = maximumValueLabel()
        self.onEditingChanged = onEditingChanged
    }
}

public extension SliderPopoverButton where Label == EmptyView, ValueLabel == EmptyView {
    init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0 ... 1, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
        self = .init(value: value, in: bounds, label: { EmptyView() }, minimumValueLabel: { EmptyView() }, maximumValueLabel: { EmptyView() }, onEditingChanged: onEditingChanged)
    }
}

public extension SliderPopoverButton where Label == EmptyView {
    init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0 ... 1, @ViewBuilder minimumValueLabel: () -> ValueLabel, @ViewBuilder maximumValueLabel: () -> ValueLabel, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
        self = .init(value: value, in: bounds, label: { EmptyView() }, minimumValueLabel: minimumValueLabel, maximumValueLabel: maximumValueLabel, onEditingChanged: onEditingChanged)
    }
}
#endif

/// A view modifier that does nothing.
public struct EmptyViewModifier: ViewModifier {

    public init() {
    }

    public func body(content: Content) -> some View {
        content
    }
}

public extension View {
    func onSpatialTapGesture(count: Int = 1, coordinateSpace: CoordinateSpace = .local, _ ended: @escaping (SpatialTapGesture.Value) -> Void) -> some View {
        gesture(SpatialTapGesture(count: count, coordinateSpace: coordinateSpace).onEnded(ended))
    }
}

// NOTE: This _could_ be considered a performance issue. IIRC common wisdom has recommended NOT doing this.
public extension View {
    @ViewBuilder
    nonisolated func modifier<T>(enabled: Bool, _ modifier: T) -> some View where T: ViewModifier {
        if enabled {
            self.modifier(modifier)
        }
        else {
            self
        }
    }
}

public extension View {
    @ViewBuilder
    func modifier(@ViewModifierBuilder _ modifier: () -> (some ViewModifier)?) -> some View {
        if let modifier = modifier() {
            self.modifier(modifier)
        }
        else {
            self
        }
    }
}
