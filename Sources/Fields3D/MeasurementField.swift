import Foundation
import SwiftUI

public struct MeasurementField <UnitType>: View where UnitType: Dimension {
    @Binding
    private var measurement: Measurement<UnitType>

    private var units: [UnitType]

    public init(measurement: Binding<Measurement<UnitType>>, units: [UnitType]) {
        self._measurement = measurement
        self.units = units
    }

    public var body: some View {
        HStack(spacing: 2) {
            TextField("?", value: $measurement.value, format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
//                .border(Color.red)
                .clipped()
                .frame(maxWidth: 60)
                .truncationMode(.tail)
//            Text(measurement.unit.symbol)
            Menu(measurement.unit.symbol) {
                ForEach(units, id: \.self) { unit in
                    Button("\(unit.symbol)") {
                        print(unit)
                        print(UnitType.baseUnit())
                        let originalValue = measurement.value
                        let baseValue = measurement.unit.converter.baseUnitValue(fromValue: originalValue)

                        let value = unit.converter.value(fromBaseUnitValue: baseValue)

                        measurement = Measurement(value: value, unit: unit)
                        print(originalValue, baseValue, value)
                    }
                }
            }
//            .border(Color.red)
//            .menuStyle(.borderlessButton)
//            .menuIndicator(.hidden)
            .frame(maxWidth: 20)
        }
        .contextMenu {
            ForEach(units, id: \.self) { unit in
                Button("\(unit.symbol)") {
                    measurement = measurement.converted(to: unit)
                }
            }
        }
        .padding(2)
        .background(.secondary.opacity(0.2))
        .cornerRadius(4)
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
    MeasurementField(measurement: $measurement, units: units)
    .padding(20)
}
