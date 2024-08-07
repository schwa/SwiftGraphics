import SwiftUI

struct GraphPaperView: View {
    let majorGridSpacing: CGFloat
    let minorGridRatio: Int
    let axisColor: Color
    let majorGridColor: Color
    let minorGridColor: Color
    let transform: CGAffineTransform

    init(
        majorGridSpacing: CGFloat,
        minorGridRatio: Int,
        axisColor: Color,
        majorGridColor: Color,
        minorGridColor: Color,
        transform: CGAffineTransform
    ) {
        self.majorGridSpacing = majorGridSpacing
        self.minorGridRatio = max(1, minorGridRatio)
        self.axisColor = axisColor
        self.majorGridColor = majorGridColor
        self.minorGridColor = minorGridColor
        self.transform = transform
    }

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                context.transform = transform

                let inverseTransform = transform.inverted()
                let transformedSize = CGSize(
                    width: size.width * inverseTransform.a + size.height * inverseTransform.c,
                    height: size.width * inverseTransform.b + size.height * inverseTransform.d
                )

                let width = abs(transformedSize.width)
                let height = abs(transformedSize.height)
                let diagonalLength = sqrt(pow(width, 2) + pow(height, 2))

                // Draw grid lines
                drawGridLines(context: context, length: diagonalLength, isXAxis: true)
                drawGridLines(context: context, length: diagonalLength, isXAxis: false)

                // Draw axes
                drawAxis(context: context, length: diagonalLength, isXAxis: true)
                drawAxis(context: context, length: diagonalLength, isXAxis: false)
            }
        }
    }

    private func drawGridLines(context: GraphicsContext, length: CGFloat, isXAxis: Bool) {
        let minorSpacing = majorGridSpacing / CGFloat(minorGridRatio)

        // Draw minor grid lines
        for position in stride(from: -length, through: length, by: minorSpacing) {
            drawLine(context: context, position: position, length: length, isXAxis: isXAxis, isMajor: false)
        }

        // Draw major grid lines
        for position in stride(from: -length, through: length, by: majorGridSpacing) where abs(position) > 0.001 * majorGridSpacing {
            drawLine(context: context, position: position, length: length, isXAxis: isXAxis, isMajor: true)
        }
    }

    private func drawLine(context: GraphicsContext, position: CGFloat, length: CGFloat, isXAxis: Bool, isMajor: Bool) {
        let start = isXAxis ? CGPoint(x: position, y: -length) : CGPoint(x: -length, y: position)
        let end = isXAxis ? CGPoint(x: position, y: length) : CGPoint(x: length, y: position)
        let path = Path { p in
            p.move(to: start)
            p.addLine(to: end)
        }

        context.stroke(path, with: .color(isMajor ? majorGridColor : minorGridColor))

        if isMajor {
            let label = String(format: "%.0f", position / majorGridSpacing)
            let labelPosition = isXAxis ? CGPoint(x: position, y: 5) : CGPoint(x: 5, y: position)
            let anchor: UnitPoint = isXAxis ? .top : .leading
            context.draw(Text(label).font(.system(size: 8)), at: labelPosition, anchor: anchor)
        }
    }

    private func drawAxis(context: GraphicsContext, length: CGFloat, isXAxis: Bool) {
        let start = isXAxis ? CGPoint(x: -length, y: 0) : CGPoint(x: 0, y: -length)
        let end = isXAxis ? CGPoint(x: length, y: 0) : CGPoint(x: 0, y: length)
        let path = Path { p in
            p.move(to: start)
            p.addLine(to: end)
        }
        context.stroke(path, with: .color(axisColor), lineWidth: 2)

        // Draw axis label
        let labelPosition = isXAxis ? CGPoint(x: 5, y: 5) : CGPoint(x: 5, y: -5)
        let anchor: UnitPoint = .topLeading
        context.draw(Text("0").font(.system(size: 8)), at: labelPosition, anchor: anchor)
    }
}

struct GraphPaperPreview: View {
    @State private var majorGridSpacing: CGFloat = 50
    @State private var minorGridRatio: Double = 5
    @State private var axisColor: Color = .black
    @State private var majorGridColor: Color = .gray.opacity(0.5)
    @State private var minorGridColor: Color = .gray.opacity(0.2)
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var translationX: CGFloat = 0.0
    @State private var translationY: CGFloat = 0.0

    var body: some View {
        VStack {
            GraphPaperView(
                majorGridSpacing: majorGridSpacing,
                minorGridRatio: Int(minorGridRatio),
                axisColor: axisColor,
                majorGridColor: majorGridColor,
                minorGridColor: minorGridColor,
                transform: CGAffineTransform.identity
                    .scaledBy(x: scale, y: scale)
                    .rotated(by: Angle(degrees: rotation).radians)
                    .translatedBy(x: translationX, y: translationY)
            )
            .border(Color.red)
            .frame(width: 300, height: 300)
            .clipShape(Rectangle())

            Group {
                HStack {
                    Text("Major Grid Spacing:")
                    Slider(value: $majorGridSpacing, in: 20...100)
                    Text(String(format: "%.1f", majorGridSpacing))
                }
                HStack {
                    Text("Minor Grid Ratio:")
                    Slider(value: $minorGridRatio, in: 1...10)
                    Text(String(format: "%.0f", minorGridRatio))
                }
                HStack {
                    Text("Axis Color:")
                    ColorPicker("", selection: $axisColor)
                }
                HStack {
                    Text("Major Grid Color:")
                    ColorPicker("", selection: $majorGridColor)
                }
                HStack {
                    Text("Minor Grid Color:")
                    ColorPicker("", selection: $minorGridColor)
                }
                HStack {
                    Text("Scale:")
                    Slider(value: $scale, in: 0.1...2)
                    Text(String(format: "%.2f", scale))
                }
                HStack {
                    Text("Rotation:")
                    Slider(value: $rotation, in: 0...360)
                    Text(String(format: "%.1f°", rotation))
                }
                HStack {
                    Text("Translation X:")
                    Slider(value: $translationX, in: -100...100)
                    Text(String(format: "%.1f", translationX))
                }
                HStack {
                    Text("Translation Y:")
                    Slider(value: $translationY, in: -100...100)
                    Text(String(format: "%.1f", translationY))
                }
            }
        }
        .padding()
    }
}

#Preview {
    GraphPaperPreview()
}
