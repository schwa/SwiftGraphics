import SwiftUI
import Fields3D

struct FieldsTestBedView: View, DemoView {

    @State
    var value = 0.0

    var body: some View {
        Wheel(value: $value)
        Text("\(value)")
    }
}
