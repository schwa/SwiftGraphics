import SwiftUI

public struct ColorPalette: View {
    let colors: [Color] = [
        .red,
        .orange,
        .yellow,
        .green,
        .mint,
        .teal,
        .cyan,
        .blue,
        .indigo,
        .purple,
        .pink,
        .brown,
        .white,
        .gray,
        .black,
        .accentColor,
        .primary,
        .secondary,
    ]

    @Binding
    var color: Color?

    public init(color: Binding<Color?>) {
        self._color = color
    }

    public var body: some View {
        #if os(macOS)
        Picker(selection: $color) {
            ForEach(colors, id: \.self) { color in
                Image(color: color, size: CGSize(width: 16, height: 16))
                    .tag(color)
            }
        } label: {
            Text("Color")
        }
        .pickerStyle(.segmented)
        #else
        fatalError()
        #endif
    }
}

#Preview {
    @Previewable @State var color: Color?

    VStack {
        ColorPalette(color: $color)
        Slider(value: .constant(0.5))
            .tint(color)
    }
    .padding()
}
