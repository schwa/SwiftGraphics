import GaussianSplatSupport
import SwiftUI

struct SplatsEditor: View {
    @Binding
    var splats: [Identified<Int, SplatD>]

    @State
    private var selection: Set<Int> = []

    @State
    private var exportData: [SplatsTransferable] = []

    @State
    private var fileExporterIsPresented: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Table(splats, selection: $selection) {
                TableColumn("Position") { row in
                    TextField("Position", value: $splats[row.id].content.position, format: .vector.compositeStyle(.list))
                        .labelsHidden()
                }
                TableColumn("Scale") { row in
                    TextField("Scale", value: $splats[row.id].content.scale, format: .vector.compositeStyle(.list))
                        .labelsHidden()
                }
                TableColumn("Color") { row in
                    HStack {
                        ColorPicker("Color", selection: $splats[row.id].content.color.srgbaLinearColor)
                            .labelsHidden()
                        TextField("Color", value: $splats[row.id].content.color.xyz, format: .vector.compositeStyle(.list))
                            .labelsHidden()
                    }
                }
                TableColumn("Alpha") { row in
                    TextField("Alpha", value: $splats[row.id].content.color.w, format: .number)
                        .labelsHidden()
                }
                TableColumn("Rotation") { row in
                    Text("\(splats[row.id].content.rotation.rollPitchYaw)")
                }
            }
            HStack {
                Button("+") {
                    splats.append(.init(id: splats.count, content: .init()))
                    selection = [splats.count - 1]
                }
                Button("-") {
                    var splats = splats
                    splats.removeAll { selection.contains($0.id) }
                    splats = splats.enumerated().map { index, splat in
                        .init(id: index, content: splat.content)
                    }
                    self.splats = splats
                }
                .buttonStyle(.bordered)
                .buttonStyle(.bordered)
                Spacer()
            }
        }
        .toolbar {
            Menu("Template") {
                Button("Splats") {
                    splats = template().enumerated().map { .init(id: $0, content: $1) }
                }
            }
            Button("Export") {
                exportData = [SplatsTransferable(splats: splats.map(\.content))]
                fileExporterIsPresented = true
            }
            .fileExporter(isPresented: $fileExporterIsPresented, items: exportData) { result in
                print(result)
            }
        }
    }
}

struct SplatsTransferable: Transferable {
    var splats: [SplatD]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { item in
            try JSONEncoder().encode(item.splats)

            //            item.splats.withUnsafeBytes { buffer in
            //                Data(buffer)
            //            }
        }
    }
}

extension SplatD {
    init() {
        self = SplatD(position: [0, 0, 0], scale: [1, 1, 1], color: [1, 1, 1, 1], rotation: .identity)
    }
}

struct SplatsEditorDemo: View {
    @State
    private var splats: [Identified<Int, SplatD>] = [
        .init(id: 0, content: .init())
    ]

    var body: some View {
        SplatsEditor(splats: $splats)
    }
}

extension SplatsEditorDemo: DemoView {
}

extension SIMD4<Float> {
    var srgbaLinearColor: Color {
        get {
            Color(.sRGBLinear, red: Double(self.x), green: Double(self.y), blue: Double(self.z), opacity: Double(self.w))
        }
        set {
            let value = newValue.resolve(in: .init())
            self = [Float(value.linearRed), Float(value.linearGreen), Float(value.linearBlue), Float(value.opacity)]
        }
    }
}

func template() -> [SplatD] {
    var splats: [SplatD] = [
        .init(position: [1, 0, 0], scale: [1, 1, 1], color: [1, 0, 0, 1], rotation: .identity),
        .init(position: [-1, 0, 0], scale: [1, 1, 1], color: [1, 0, 0, 1], rotation: .identity),
        .init(position: [0, 1, 0], scale: [1, 1, 1], color: [0, 1, 0, 1], rotation: .identity),
        .init(position: [0, -1, 0], scale: [1, 1, 1], color: [0, 1, 0, 1], rotation: .identity),
        .init(position: [0, 0, 1], scale: [1, 1, 1], color: [0, 0, 1, 1], rotation: .identity),
        .init(position: [0, 0, -1], scale: [1, 1, 1], color: [0, 0, 1, 1], rotation: .identity),
    ]
    splats = splats.map { splat in
        var splat = splat
        splat.scale *= 0.1
        return splat
    }

    return splats
}
