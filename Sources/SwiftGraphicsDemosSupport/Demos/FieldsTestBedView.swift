import SwiftUI
import Fields3D
import CoreGraphicsSupport

struct FieldsTestBedView: View, DemoView {

    @State
    var value = 0.0

    @State
    var morpher = PathMorpher(a: Path.line(from: [0, 0], to: [100, 0]), b: .smileyFace(in: [0, 0, 100, 100]))

    var body: some View {
        VStack {
//            WrappingHStack {
//                let items: [String] = Array(1...20).map { "Item \($0)" }
//
//                ForEach(items, id: \.self) { item in
//                    Text(item)
//                        .padding()
//                        .background(Color.blue)
//                        .cornerRadius(8)
//                }
//            }
//            .border(Color.red)
//            .padding(32)

            VStack {
                PathSlider(value: $value, path: morpher.morph(value))

                Text("\(value.formatted())")
                Slider(value: $value)
            }
            .padding()

//            Wheel(label: "Hello", value: $value)
//            Text("\(value)")
//            Button("Boing") {
//                withAnimation {
//                    value += Double.random(in: 0..<1000)
//                }
//            }
//            Slider(value: $value, in: -1000 ... 1000)
//
//            Dial(value: $value, in: -1000 ... 1000) {
//                Text("Hello")
//            }
        }
    }
}
