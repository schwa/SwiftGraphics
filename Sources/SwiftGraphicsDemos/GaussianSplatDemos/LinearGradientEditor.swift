import SwiftUI

struct LinearGradient: Equatable {
    var stops: [Gradient.Stop] = []
    var startPoint: UnitPoint
    var endPoint: UnitPoint
}

extension LinearGradient {
    func shading(size: CGSize) -> GraphicsContext.Shading {
        let gradient = Gradient(stops: stops.sorted(by: { $0.location < $1.location }))
        return .linearGradient(gradient, startPoint: CGPoint(x: size.width * startPoint.x, y: size.height * startPoint.y), endPoint: CGPoint(x: size.width * endPoint.x, y: size.height * endPoint.y))
    }

    func image(size: CGSize) -> Image {
        Image(size: size) { context in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: shading(size: size))
        }
    }
}

struct LinearGradientEditor: View {
    @Binding
    var value: LinearGradient

    @State
    var showPopover: Bool = false

    var body: some View {
        Button(role: .none) {
            showPopover = true
        } label: {
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: value.shading(size: size))
            }
        }
        .frame(width: 64, height: 64)
        .popover(isPresented: $showPopover) {
            Form {
                Canvas { context, size in
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: value.shading(size: size))
                }
                .frame(width: 100, height: 100)
                Section("Start") {
                    TextField("X", value: $value.startPoint.x.double, format: .number)
                    TextField("Y", value: $value.startPoint.y.double, format: .number)
                }
                Section("End") {
                    TextField("X", value: $value.endPoint.x.double, format: .number)
                    TextField("Y", value: $value.endPoint.y.double, format: .number)
                }
                Section("Stops") {
                    List($value.stops.indices, id: \.self) { index in
                        HStack {
                            ColorPicker("Color \(index+1)", selection: $value.stops[index].color)
                            TextField("Stop \(index+1)", value: $value.stops[index].location.double, format: .number)
                        }
                        .labelsHidden()
                    }
                }
            }
            .padding()
            .frame(minWidth: 240, minHeight: 480)
        }
    }
}

private extension CGFloat {
    var double: Double {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}
