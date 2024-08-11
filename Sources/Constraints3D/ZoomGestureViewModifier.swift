import BaseSupport
import SwiftUI

public struct ZoomGestureViewModifier: ViewModifier {
    @Binding
    var zoom: Float

    var range: ClosedRange<Float>

    @State
    var initialZoom: Float?

    public init(zoom: Binding<Float>, range: ClosedRange<Float>) {
        self._zoom = zoom
        self.range = range
    }

    public func body(content: Content) -> some View {
        content
            .gesture(magnifyGesture)
    }

    func magnifyGesture() -> some Gesture {
        MagnifyGesture()
            .onEnded { _ in
                initialZoom = nil
            }
            .onChanged { value in
                if initialZoom == nil {
                    initialZoom = zoom
                }
                guard let initialZoom else {
                    fatalError("Cannot zoom without an initial zoom value.")
                }
                zoom = clamp(initialZoom / Float(value.magnification), to: range)
            }
    }
}

public extension View {
    func zoomGesture(zoom: Binding<Float>, range: ClosedRange<Float> = -.infinity ... .infinity) -> some View {
        modifier(ZoomGestureViewModifier(zoom: zoom, range: range))
    }
}
