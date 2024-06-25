import SwiftUI
import Fields3D
import CoreGraphicsSupport

struct FieldsTestBedView: View, DemoView {

    @State
    var value = 0.0

//    @State
    //var path = Path.curve(from: [0, 0], to: [100, 0], control1: [0, 0], control2: [100, 0])

    var path = Path.spiral(center: [100, 100], initialRadius: 1, finalRadius: 100, turns: 3)

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
                PathSlider(value: $value, path: path, range: 0...1)
//                    .onChange(of: value) {
//                        let cp1: CGPoint = lerp(from: [0, 0], to: [0, 100], by: value)
//                        let cp2: CGPoint = lerp(from: [100, 0], to: [100, 100], by: value)
//
//                        self.path = Path.curve(from: [0, 0], to: [100, 0], control1: cp1, control2: cp2)
//
//                    }
                Text("\(value.formatted())")
                //Slider(value: $value)
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
