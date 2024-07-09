import CoreGraphicsSupport
import Fields3D
import SwiftUI

struct FieldsTestBedView: View, DemoView {
    @State
    var m = Measurement(value: 90, unit: UnitAngle.degrees)

    var body: some View {
        MeasurementField(measurement: $m, units: [UnitAngle.degrees, UnitAngle.radians, UnitAngle.revolutions, UnitAngle.arcMinutes, UnitAngle.arcSeconds, UnitAngle.gradians])
    }
}

//struct FieldsTestBedView: View, DemoView {
//    @State
//    private var value = 0.0
//
//    @State
//    private var morpher = PathMorpher(a: Path.line(from: [0, 0], to: [100, 0]), b: .smileyFace(in: [0, 0, 100, 100]))
//
//    var body: some View {
//        VStack {
//            //            HilbertCurve()
//
//            //            WrappingHStack {
//            //                let items: [String] = Array(1...20).map { "Item \($0)" }
//            //
//            //                ForEach(items, id: \.self) { item in
//            //                    Text(item)
//            //                        .padding()
//            //                        .background(Color.blue)
//            //                        .cornerRadius(8)
//            //                }
//            //            }
//            //            .border(Color.red)
//            //            .padding(32)
//
//            VStack {
//                PathSlider(value: $value, path: morpher.morph(value))
//
//                Text("\(value.formatted())")
//                Slider(value: $value)
//            }
//            .padding()
//
//            //            Wheel(label: "Hello", value: $value)
//            //            Text("\(value)")
//            //            Button("Boing") {
//            //                withAnimation {
//            //                    value += Double.random(in: 0..<1000)
//            //                }
//            //            }
//            //            Slider(value: $value, in: -1000 ... 1000)
//            //
//            //            Dial(value: $value, in: -1000 ... 1000) {
//            //                Text("Hello")
//            //            }
//        }
//    }
//}
