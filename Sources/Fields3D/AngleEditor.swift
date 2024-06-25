import SwiftUI
import SwiftFormats
import CoreGraphicsSupport

public struct AngleEditor: View {
    let titleKey: LocalizedStringKey?

    @Binding
    var value: Angle

    let prompt: Text?

    public init(_ titleKey: LocalizedStringKey? = nil, value: Binding<Angle>, prompt: Text? = nil) {
        self.titleKey = titleKey
        self._value = value
        self.prompt = prompt
    }

    public var body: some View {
        TextField(titleKey ?? "", value: $value, format: .angle, prompt: prompt)
    }
}

#Preview {
    @Previewable @State var angle = Angle.degrees(45)
    Form {
        HStack {
            AngleEditor("Angle", value: $angle, prompt: Text("Angle"))
                .frame(maxWidth: 160)
            Dial(value: $angle.degrees, in: 0...100)
        }
    }
    .padding()
}
