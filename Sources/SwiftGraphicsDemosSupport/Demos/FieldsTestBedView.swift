import SwiftUI
import Fields3D

struct FieldsTestBedView: View, DemoView {

    @State
    var value = 0.0

    var body: some View {
        Wheel(label: "Hello", value: $value)
        Text("\(value)")
        Button("Boing") {
            withAnimation {
                value += Double.random(in: 0..<1000)
            }
        }
        Slider(value: $value, in: -1000 ... 1000)

    }
}
