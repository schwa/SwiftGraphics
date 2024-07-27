import SwiftUI

struct SwiftUIShaderDemoView: DemoView {

    @State
    var offset: CGPoint = [20, 20]

    var body: some View {
        ZStack {
            Color.white
                .colorEffect(ShaderFunction.stripeFunction(color1: .red, color2: .black, width: offset.distance, gap: offset.distance, angle: offset.angle))
            Circle().fill(Color.black).frame(width: 20, height: 20)
                .contentShape(Circle())
                .gesture {
                    DragGesture().onChanged { value in
                        offset = CGPoint(value.translation)
                        print(offset)
                    }
                }
            Circle().fill(Color.white).frame(width: 20, height: 20)
                .offset(offset)
                .allowsHitTesting(false)
        }
    }
}

extension ShaderFunction {
    static func stripeFunction(color1: Color, color2: Color? = nil, width: Double, gap: Double? = nil, angle: Angle) -> Shader {
        let x = cos(angle.radians)
        let y = sin(angle.radians)
        let function = ShaderLibrary.bundle(.module).shader_demo
        return function(.color(color1), .color(color2 ?? .clear), .float(width), .float(gap ?? width), .float2(x, y))
    }
}
