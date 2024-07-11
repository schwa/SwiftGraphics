import SwiftUI

public struct TickMarks: View {
    public enum Orientation {
        case horizontal
        case vertical
    }

    public struct Style {
        public var majorTickLength: CGFloat
        public var minorTickLength: CGFloat
        public var majorLineWidth: CGFloat
        public var minorLineWidth: CGFloat
        public var majorTickColor: Color
        public var minorTickColor: Color

        public init() {
            self.majorTickLength = 8
            self.minorTickLength = 4
            self.majorLineWidth = 1.6
            self.minorLineWidth = 1
            self.majorTickColor = Color.primary.opacity(0.75)
            self.minorTickColor = Color.secondary.opacity(0.75)
        }
    }

    var from: Double
    var to: Double
    var majorDistance: Double
    var minorDistance: Double
    var orientation: Orientation
    var showLabels: Bool
    var style: Style
    var formatLabel: ((Double) -> Text)?

    @Environment(\.layoutDirection)
    private var layoutDirection

    public init(from: Double, to: Double, majorDistance: Double, minorDistance: Double, orientation: Orientation, showLabels: Bool = true, style: Style = Style(), formatLabel: ((Double) -> Text)? = nil) {
        self.from = from
        self.to = to
        self.majorDistance = majorDistance
        self.minorDistance = minorDistance
        self.orientation = orientation
        self.showLabels = showLabels
        self.style = style
        self.formatLabel = formatLabel
    }

    public var body: some View {
        Canvas { context, size in
            let rangeSpan = abs(to - from)
            assert(rangeSpan > 0, "Range span must be greater than zero")
            let pixelsPerUnit = (orientation == .horizontal ? size.width : size.height) / CGFloat(rangeSpan)

            let (start, end) = from < to ? (from, to) : (to, from)
            let firstMajorTick = ceil(start / majorDistance) * majorDistance

            let spaceForMinorTicks = (majorDistance * pixelsPerUnit) > (style.minorLineWidth * 3)

            for majorValue in stride(from: firstMajorTick, through: end, by: majorDistance) {
                if majorValue >= start && majorValue <= end {
                    let position = CGFloat(abs(majorValue - from)) * pixelsPerUnit
                    drawTick(context: context, at: position, isMajor: true, size: size)

                    if showLabels {
                        drawLabel(context: context, at: position, value: majorValue, size: size)
                    }
                }

                if spaceForMinorTicks {
                    for minorValue in stride(from: majorValue + minorDistance, to: majorValue + majorDistance, by: minorDistance) {
                        if minorValue >= start && minorValue <= end {
                            let minorPosition = CGFloat(abs(minorValue - from)) * pixelsPerUnit
                            drawTick(context: context, at: minorPosition, isMajor: false, size: size)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tick marks from \(from) to \(to)")
        .frame(minWidth: minWidth, minHeight: minHeight)
    }

    private var minHeight: CGFloat? {
        guard orientation == .horizontal, showLabels else {
            return nil
        }
        return label(for: from).size().map { style.majorTickLength + $0.height }
    }

    private var minWidth: CGFloat? {
        guard orientation == .vertical, showLabels else {
            return nil
        }
        return label(for: from).size().map { style.majorTickLength + $0.width + 4 }
    }

    private func label(for value: Double) -> Text {
        formatLabel?(value) ?? Text(value.formatted())
            .font(.caption2)
            .foregroundStyle(.primary.opacity(0.6))
            .accessibilityLabel("Tick mark \(value.formatted())")
    }

    private func drawTick(context: GraphicsContext, at position: CGFloat, isMajor: Bool, size: CGSize) {
        let length = isMajor ? style.majorTickLength : style.minorTickLength
        let lineWidth = isMajor ? style.majorLineWidth : style.minorLineWidth
        let color = isMajor ? style.majorTickColor : style.minorTickColor

        var path = Path()
        switch orientation {
        case .horizontal:
            path.move(to: CGPoint(x: position, y: size.height))
            path.addLine(to: CGPoint(x: position, y: size.height - length))
        case .vertical:
            let x = layoutDirection == .rightToLeft ? size.width : 0
            path.move(to: CGPoint(x: x, y: position))
            path.addLine(to: CGPoint(x: layoutDirection == .rightToLeft ? size.width - length : length, y: position))
        }
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
    }

    private func drawLabel(context: GraphicsContext, at position: CGFloat, value: Double, size: CGSize) {
        let label = label(for: value)
        let resolvedText = context.resolve(label)

        switch orientation {
        case .horizontal:
            context.draw(resolvedText, at: CGPoint(x: position, y: size.height - style.majorTickLength), anchor: .bottom)
        case .vertical:
            let x = layoutDirection == .rightToLeft ? size.width - style.majorTickLength - 2 : style.majorTickLength + 2
            let anchor: UnitPoint = layoutDirection == .rightToLeft ? .trailing : .leading
            context.draw(resolvedText, at: CGPoint(x: x, y: position), anchor: anchor)
        }
    }
}

public extension TickMarks {
    init(range: ClosedRange<Double>, majorDistance: Double, minorDistance: Double, orientation: Orientation, showLabels: Bool = true, style: Style = Style(), formatLabel: ((Double) -> Text)? = nil) {
        self.init(from: range.lowerBound, to: range.upperBound, majorDistance: majorDistance, minorDistance: minorDistance, orientation: orientation, showLabels: showLabels, style: style, formatLabel: formatLabel)
    }
}

extension View {
    // TODO: This is evil. EVIL.
    func size(proposedSize: ProposedViewSize = .unspecified) -> CGSize? {
        let renderer = ImageRenderer(content: self)
        renderer.proposedSize = proposedSize
        guard let image = renderer.cgImage else {
            return nil
        }
        return CGSize(width: image.width, height: image.height)
    }
}

#Preview {
    HStack(alignment: .top, spacing: 20) {
        VStack(spacing: 20) {
            Text("Horizontal Examples").font(.headline)
            TickMarks(range: 0...100, majorDistance: 10, minorDistance: 2, orientation: .horizontal)
                .frame(width: 300, height: 20)
                    .border(Color.red)
            TickMarks(range: 0...1, majorDistance: 0.2, minorDistance: 0.05, orientation: .horizontal)
                .frame(width: 300, height: 20)
            TickMarks(from: 100, to: 0, majorDistance: 10, minorDistance: 2, orientation: .horizontal)
                .frame(width: 300, height: 20)
            TickMarks(from: 1, to: -1, majorDistance: 0.5, minorDistance: 0.1, orientation: .horizontal) { value in
                Text("\(value, specifier: "%.2f")°").foregroundColor(.blue).bold()
            }
            .frame(width: 300, height: 25)
        }

        VStack(spacing: 20) {
            Text("Vertical Examples").font(.headline)
            HStack(spacing: 20) {
                TickMarks(range: 0...100, majorDistance: 10, minorDistance: 2, orientation: .vertical)
                    .frame(height: 300)
                    .border(Color.red)
                TickMarks(range: 0...1, majorDistance: 0.2, minorDistance: 0.05, orientation: .vertical)
                    .frame(height: 300)
                TickMarks(from: 100, to: 0, majorDistance: 10, minorDistance: 2, orientation: .vertical)
                    .frame(height: 300)
                TickMarks(from: 1, to: -1, majorDistance: 0.5, minorDistance: 0.1, orientation: .vertical) { value in
                    Text("\(value, specifier: "%.2f")°").foregroundColor(.blue).bold()
                }
                .frame(height: 300)
            }
        }
    }
    .padding()
}
