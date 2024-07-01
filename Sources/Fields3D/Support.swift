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
