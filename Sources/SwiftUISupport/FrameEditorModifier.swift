import SwiftUI

public struct FrameEditorModifier: ViewModifier {
    @State
    var isExpanded = false

    @State
    var locked = false

    @State
    var lockedSize: CGSize?

    @State
    var size: CGSize = .zero

    @Environment(\.displayScale)
    var displayScale

    let resolutions = [
        // https://iosref.com/res
        ("iPhone 15 Pro Max", 3.0, CGSize(width: 1290, height: 2796)),
        ("iPhone 14 Pro Max", 3.0, CGSize(width: 1290, height: 2796)),
        ("iPhone 15 Plus", 3.0, CGSize(width: 1290, height: 2796)),
        ("iPhone 15 Pro", 3.0, CGSize(width: 1179, height: 2556)),
        ("iPhone 15", 3.0, CGSize(width: 1179, height: 2556)),
        ("iPhone 14 Pro", 3.0, CGSize(width: 1179, height: 2556)),
        ("iPhone 11 Pro", 3.0, CGSize(width: 828, height: 1792)),
    ]

    public func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self, of: \.size) {
                size = $0
            }
            .frame(width: lockedSize?.width, height: lockedSize?.height)
            .overlay(alignment: .topLeading) {
                DisclosureGroup(isExpanded: $isExpanded) {
                    control()
                } label: {
                    Image(systemName: "rectangle.split.2x2")
                }
                .disclosureGroupStyle(MyDisclosureGroupStyle())
                .foregroundStyle(Color.white)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.mint))
                .padding()
            }
    }

    func control() -> some View {
        HStack {
            VStack {
                if let lockedSize {
                    TextField("Size", value: .constant(lockedSize), format: .size)
                        .foregroundStyle(.black)
                        .frame(maxWidth: 120)
                }
                else {
                    Text("\(size, format: .size)")
                    Text("\(size.width / size.height, format: .number)")
                }
                Menu("Devices") {
                    ForEach(resolutions, id: \.0) { resolution in
                        Button("\(resolution.0) (\(resolution.2) @ \(resolution.1)x)") {
                            lockedSize = CGSize(width: resolution.2.width / displayScale, height: resolution.2.height / displayScale)
                        }
                    }
                }
                .fixedSize()
            }

            Button(systemImage: locked ? "lock" : "lock.open") {
                withAnimation {
                    locked.toggle()
                    lockedSize = locked ? size : nil
                }
            }
            .buttonStyle(.borderless)
        }
    }
}

public extension View {
    func showFrameEditor() -> some View {
        modifier(FrameEditorModifier())
    }
}
