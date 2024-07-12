import Foundation
import SwiftUI

public struct MeasurementField <Label, UnitType>: View where Label: View, UnitType: Dimension {
    @Binding
    private var measurement: Measurement<UnitType>
    private var units: [UnitType]
    private var prompt: Text?
    private var label: Label

    public init(measurement: Binding<Measurement<UnitType>>, units: [UnitType], prompt: Text? = nil, @ViewBuilder label: () -> Label) {
        self._measurement = measurement
        self.units = units
        self.prompt = prompt
        self.label = label()
    }

    public var body: some View {
        HStack(spacing: 2) {
            HStack {
                label
                TextField(value: $measurement.value, format: .number, prompt: prompt) { EmptyView() }
                .foregroundColor(.primary.opacity(0.5))
                .labelsHidden()
            }
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .clipped()
            .truncationMode(.tail)
            if units.count == 1 {
                Text(measurement.unit.symbol)
                    .foregroundColor(.primary.opacity(0.5))
            }
            else {
                Menu(measurement.unit.symbol) {
                    ForEach(units, id: \.self) { unit in
                        Button("\(unit.symbol)") {
                            measurement = measurement.converted(to: unit)
                        }
                    }
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
        }
        .contextMenu {
            ForEach(units, id: \.self) { unit in
                Button("\(unit.symbol)") {
                    measurement = measurement.converted(to: unit)
                }
            }
        }
        .padding(2)
        .background(.secondary.opacity(0.1))
        .cornerRadius(4)
//        .onScrollWheelUp { direction in
//            if direction == .up {
//                measurement.value += 1
//            }
//            if direction == .down {
//                measurement.value += 1
//            }
//        }
    }
}

public extension MeasurementField where Label == EmptyView {
    init(measurement: Binding<Measurement<UnitType>>, units: [UnitType], prompt: Text? = nil) {
        self.init(measurement: measurement, units: units, prompt: prompt) { EmptyView() }
    }
}

public extension MeasurementField where Label == Text {
    init(title: LocalizedStringKey, measurement: Binding<Measurement<UnitType>>, units: [UnitType], prompt: Text? = nil) {
        self.init(measurement: measurement, units: units, prompt: prompt) { Text(title) }
    }
}

#Preview {
    @Previewable @State
    var measurement = Measurement(value: 90, unit: UnitAngle.degrees)

    let units = [
        UnitAngle.degrees,
        UnitAngle.radians,
        UnitAngle.gradians,
        UnitAngle.revolutions,
    ]
    MeasurementField(title: "Angle", measurement: $measurement, units: units)
        .frame(width: 120)
        .padding(20)
}

//import Combine
//
//struct ScrollWheelModifier: ViewModifier {
//
//    enum Direction {
//        case up, down, left, right
//    }
//
//    @State private var subs = Set<AnyCancellable>() // Cancel onDisappear
//
//    var action: (Direction) -> Void
//
//    func body(content: Content) -> some View {
//        content
//            .onAppear { trackScrollWheel() }
//    }
//
//    func trackScrollWheel() {
//        NSApp.publisher(for: \.currentEvent)
//            .filter { event in event?.type == .scrollWheel }
//            .throttle(for: .milliseconds(200),
//                      scheduler: DispatchQueue.main,
//                      latest: true)
//            .sink {
//                if let event = $0 {
//                    if event.deltaX > 0 {
//                        action(.right)
//                    }
//
//                    if event.deltaX < 0 {
//                        action(.left)
//                    }
//
//                    if event.deltaY > 0 {
//                        action(.down)
//                    }
//
//                    if event.deltaY < 0 {
//                        action(.up)
//                    }
//                }
//            }
//            .store(in: &subs)
//    }
//}
//
//extension View {
//    func onScrollWheelUp(action: @escaping (ScrollWheelModifier.Direction) -> Void) -> some View {
//        modifier(ScrollWheelModifier(action: action) )
//    }
//}
