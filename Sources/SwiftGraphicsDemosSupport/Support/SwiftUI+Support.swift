import SwiftUI

#if !os(tvOS)
struct MyDisclosureGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
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

struct SliderPopoverButton<Label, ValueLabel>: View where Label: View, ValueLabel: View {
    @Binding
    var value: Double

    var bounds: ClosedRange<Double>

    var label: Label
    var minimumValueLabel: ValueLabel
    var maximumValueLabel: ValueLabel
    var onEditingChanged: (Bool) -> Void

    @State
    private var isPresented = false

    var body: some View {
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

extension SliderPopoverButton where Label == EmptyView, ValueLabel == EmptyView {
    init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0 ... 1, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
        self = .init(value: value, in: bounds, label: { EmptyView() }, minimumValueLabel: { EmptyView() }, maximumValueLabel: { EmptyView() }, onEditingChanged: onEditingChanged)
    }
}

extension SliderPopoverButton where Label == EmptyView {
    init<V>(value: Binding<V>, in bounds: ClosedRange<V> = 0 ... 1, @ViewBuilder minimumValueLabel: () -> ValueLabel, @ViewBuilder maximumValueLabel: () -> ValueLabel, onEditingChanged: @escaping (Bool) -> Void = { _ in }) where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
        self = .init(value: value, in: bounds, label: { EmptyView() }, minimumValueLabel: minimumValueLabel, maximumValueLabel: maximumValueLabel, onEditingChanged: onEditingChanged)
    }
}
#endif

struct FrameEditorModifier: ViewModifier {
    @State
    var isExpanded = false

    @State
    var locked = false

    @State
    var lockedSize: CGSize?

    func body(content: Content) -> some View {
        content
            .frame(width: lockedSize?.width, height: lockedSize?.height)
            .overlay {
                GeometryReader { proxy in
                    DisclosureGroup(isExpanded: $isExpanded) {
                        HStack {
                            VStack {
                                if let lockedSize {
                                    TextField("Size", value: .constant(lockedSize), format: .size)
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: 120)
                                    //                                Text("\(proxy.size.width / proxy.size.height, format: .number)")
                                }
                                else {
                                    Text("\(proxy.size, format: .size)")
                                    Text("\(proxy.size.width / proxy.size.height, format: .number)")
                                }
                            }
                            Button(systemImage: locked ? "lock" : "lock.open") {
                                withAnimation {
                                    locked.toggle()
                                    lockedSize = locked ? proxy.size : nil
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                    } label: {
                        Image(systemName: "rectangle.split.2x2")
                    }
                    .disclosureGroupStyle(MyDisclosureGroupStyle())
                    .foregroundStyle(Color.white)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.mint))
                    .padding()
                    .frame(alignment: .topLeading)
                }
            }
    }
}

extension View {
    func showFrameEditor() -> some View {
        modifier(FrameEditorModifier())
    }
}
