import SwiftUI

struct GeometrySizeChangeViewModifier: ViewModifier {
    @Binding
    var size: CGSize

    func body(content: Content) -> some View {
        content
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        }
        action: { size in
            self.size = size
        }
    }
}

extension View {
    func geometrySize(_ size: Binding<CGSize>) -> some View {
        self.modifier(GeometrySizeChangeViewModifier(size: size))
    }
}

func wrap(_ value: Double, within range: ClosedRange<Double>) -> Double {
    let size = range.upperBound - range.lowerBound
    let normalized = value - range.lowerBound
    return (normalized.truncatingRemainder(dividingBy: size) + size).truncatingRemainder(dividingBy: size) + range.lowerBound
}

func wrap(_ point: CGPoint, within rect: CGRect) -> CGPoint {
    CGPoint(
        x: wrap(point.x, within: rect.minX ... rect.maxX),
        y: wrap(point.y, within: rect.minY ... rect.maxY)
    )
}

func sign(_ v: Double) -> Double {
    if v < 0 {
        return -1
    }
    else if v == 0 {
        return 0
    }
    else {
        return 1
    }
}

public extension FloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }

    func wrapped(to range: ClosedRange<Self>) -> Self {
        let rangeSize = range.upperBound - range.lowerBound
        let wrappedValue = (self - range.lowerBound).truncatingRemainder(dividingBy: rangeSize)
        return (wrappedValue < 0 ? wrappedValue + rangeSize : wrappedValue) + range.lowerBound
        return wrappedValue + range.lowerBound
    }
}



extension Image {
    @MainActor
    init(color: Color, size: CGSize) {
        let nsImage = ImageRenderer(content: color.frame(width: size.width, height: size.height)).nsImage!
        self = .init(nsImage: nsImage)
    }
}

extension ControlSize {
    var ratio: UnitPoint {
        switch self {
        case .mini:
            .init(x: 0.7, y: 0.65)
        case .small:
            .init(x: 0.8, y: 0.8)
        case .regular:
            .init(x: 1, y: 1)
        case .large:
            .init(x: 1, y: 1.4)
        case .extraLarge:
            .init(x: 1, y: 1.4)
        @unknown default:
            .init(x: 1, y: 1)
        }
    }
}

struct RedlineModifier: ViewModifier {
    @State
    var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
        .geometrySize($size)
        .overlay {
            Text("\(size.height.formatted())").foregroundStyle(.red).font(.footnote).background(.thickMaterial)
        }
    }
}

extension View {
    func redline() -> some View {
        modifier(RedlineModifier())
    }
}


public extension Path {

    static func curve(from: CGPoint, to: CGPoint, control1: CGPoint, control2: CGPoint) -> Path {
        Path { path in
            path.move(to: from)
            path.addCurve(to: to, control1: control1, control2: control2)
        }
    }

    var firstPoint: CGPoint? {
        var firstPoint: CGPoint?
        forEach { element in
            guard firstPoint == nil else {
                return
            }
            switch element {
            case .move(let point):
                firstPoint = point
            default:
                firstPoint = .zero
            }
        }
        return firstPoint
    }
}

public extension Path {

    static func spiral(center: CGPoint, initialRadius: Double, finalRadius: Double, turns: Double) -> Path {
        var path = Path()

        let points = 500 // Increase for smoother spiral
        let angleIncrement = 2 * Double.pi * turns / Double(points)
        let radiusIncrement = (finalRadius - initialRadius) / Double(points)

        var angle = 0.0
        var radius = initialRadius

        var currentPoint = CGPoint(x: center.x + CGFloat(radius * cos(angle)),
                                   y: center.y + CGFloat(radius * sin(angle)))
        path.move(to: currentPoint)

        for _ in 0..<points {
            angle += angleIncrement
            radius += radiusIncrement
            let nextPoint = CGPoint(x: center.x + CGFloat(radius * cos(angle)),
                                    y: center.y + CGFloat(radius * sin(angle)))
            let controlPoint = CGPoint(x: (currentPoint.x + nextPoint.x) / 2,
                                       y: (currentPoint.y + nextPoint.y) / 2)
            path.addQuadCurve(to: nextPoint, control: controlPoint)
            currentPoint = nextPoint
        }

        return path
    }
}
