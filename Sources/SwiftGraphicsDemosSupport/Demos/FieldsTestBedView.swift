import SwiftUI
import Fields3D

struct FieldsTestBedView: View, DemoView {

    @State
    var value = 0.0

    var body: some View {
        Wheel(label: "Hello", value: $value)
        Text("\(value)")
        Button("Boing") {
            value += Double.random(in: 0..<1000)
        }

    }
}
