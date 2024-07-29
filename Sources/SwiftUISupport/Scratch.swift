import SwiftUI

struct HorizontalAxisView: View {
    let length: CGFloat
    let ticks: Int
    let range: ClosedRange<Double>

    var body: some View {
        Canvas { context, size in
            let tickSpacing = length / CGFloat(ticks - 1)

            // Draw the main axis line
            let axisPath = Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))
            }
            context.stroke(axisPath, with: .color(.black), lineWidth: 2)

            // Draw ticks and labels
            for i in 0..<ticks {
                let position = CGFloat(i) * tickSpacing

                // Draw tick
                let tickPath = Path { path in
                    path.move(to: CGPoint(x: position, y: 0))
                    path.addLine(to: CGPoint(x: position, y: 10))
                }
                context.stroke(tickPath, with: .color(.black), lineWidth: 1)

                // Draw label
                let value = range.lowerBound + (range.upperBound - range.lowerBound) * Double(i) / Double(ticks - 1)
                let text = Text(String(format: "%.1f", value)).font(.caption)
                let textPoint = CGPoint(x: position, y: 10)
                context.draw(text, at: textPoint, anchor: .top)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.white
        HorizontalAxisView(length: 300, ticks: 6, range: 0...100)
    }
}
