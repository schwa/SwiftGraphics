import BaseSupport
import Charts
import GaussianSplatSupport
import simd
import SwiftFormats
import SwiftUI
import UniformTypeIdentifiers

public struct SplatCloudInfoView: View {
    @State
    private var splats: [SplatB] = []

    @State
    private var isPresented = false

    @State
    private var isTargeted = false

    public init() {
    }

    public var body: some View {
        ScrollView {
            VStack {
                let splats = splats
                Button("Load") {
                    isPresented = true
                }
                Divider()
                LabeledContent("# splats", value: splats.count, format: .number)

                //                TaskView(id: splats, "Bounding box") {
                //                    let positions = splats.map { SIMD3<Float>($0.position) }
                //                    let minimums = positions.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], min)
                //                    let maximums = positions.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], max)
                //                    let size = maximums - minimums
                //                    return "\(minimums, format: .vector) ... \(maximums, format: .vector), size: (\(size, format: .vector))"
                //                }

                Text("Splat size: \(bytes(splats.count * MemoryLayout<SplatB>.stride).formatted())")
                TaskView(id: splats, "Low Hanging Fruit Size") {
                    bytes(computeLowHangingFruitSize(splats: splats)).formatted()
                }

                TaskView(id: splats) {
                    Set(splats.map(\.rotation))
                }
                content: { uniqueRotations in
                    LabeledContent("# unique rotations", value: uniqueRotations.count, format: .number)
                    LabeledContent("# unique rotations (bits)", value: log2(Double(uniqueRotations.count)), format: .number)
                }

                TaskView(id: splats) {
                    Set(splats.map(\.color))
                }
                content: { uniqueColors in
                    LabeledContent("# unique (RGBA) colors", value: uniqueColors.count, format: .number)
                    LabeledContent("# unique (RGBA) colors (bits)", value: log2(Double(uniqueColors.count)), format: .number)
                }

                //                TaskView(id: splats, "# unique position") { Set(splats.map(\.position)).count }
                //                TaskView(id: splats, "# unique x") { Set(splats.map(\.position.x)).count }
                //                TaskView(id: splats, "# unique y") { Set(splats.map(\.position.y)).count }
                //                TaskView(id: splats, "# unique z") { Set(splats.map(\.position.z)).count }

                TaskView(id: splats) {
                    channelInfo(splats: splats)
                }
                content: { channelInfo in
                    ForEach(channelInfo, id: \.name) { data in
                        Chart {
                            LinePlot(data.frequency, x: .value(data.name, \.0), y: .value("Frequency", \.1))
                                .foregroundStyle(data.color)
                        }
                        .chartXScale(domain: 0 ... 255)
                        .frame(maxHeight: 50)
                    }
                }
            }
            .onAppear {
                let url = Bundle.module.url(forResource: "train", withExtension: "splat")!
                splats = try! load(url: url)
            }
            .fileImporter(isPresented: $isPresented, allowedContentTypes: [.splat]) { result in
                if case let .success(url) = result {
                    do {
                        splats = try load(url: url)
                    }
                    catch {
                        fatalError(error)
                    }
                }
            }
            .onDrop(of: [.splat], isTargeted: $isTargeted) { items in
                if let item = items.first {
                    item.loadItem(forTypeIdentifier: UTType.splat.identifier, options: nil) { data, _ in
                        guard let url = data as? URL else {
                            return
                        }
                        Task {
                            await MainActor.run {
                                splats = try! load(url: url)
                            }
                        }
                    }
                    return true
                } else {
                    return false
                }
            }
            .border(isTargeted ? Color.accentColor : .clear, width: isTargeted ? 4 : 0)
        }
    }
}

func bytes(_ bytes: Int) -> Measurement<UnitInformationStorage> {
    Measurement(value: Double(bytes), unit: UnitInformationStorage.bytes)
}

struct ChannelInfo: Sendable {
    var name: String
    var color: Color
    var frequency: [(UInt8, Int)]
}

func channelInfo(splats: [SplatB]) -> [ChannelInfo] {
    let channels = [
        ("Red", Color.red, 0),
        ("Green", Color.green, 1),
        ("Blue", Color.blue, 2),
        ("Alpha", Color.black, 3),
    ]

    return channels.map { channel in
        ChannelInfo(name: channel.0, color: channel.1, frequency: Array(splats.map { $0.color[channel.2] }.frequency().sorted(by: \.0).dropFirst().dropLast()))
    }
}

func load(url: URL) throws -> [SplatB] {
    let data = try Data(contentsOf: url)
    return data.withUnsafeBytes { buffer in
        buffer.withMemoryRebound(to: SplatB.self) { splats in
            Array(splats)
        }
    }
}

extension Collection where Element: Hashable {
    func frequency() -> [(Element, Int)] {
        var frequency: [Element: Int] = [:]
        for element in self {
            let count = frequency[element, default: 0]
            frequency[element] = count + 1
        }
        return Array(frequency)
    }
}

struct TaskView <ID, Value, Content>: View where ID: Equatable, Value: Sendable, Content: View {
    let id: ID
    let closure: @Sendable () -> Value
    let content: (Value) -> Content

    @State
    private var value: Value?

    init(id: ID, closure: @Sendable @escaping () -> Value, @ViewBuilder content: @escaping (Value) -> Content, value: Value? = nil) {
        self.id = id
        self.closure = closure
        self.content = content
        self.value = value
    }

    var body: some View {
        Group {
            if let value {
                content(value)
            }
            else {
                ProgressView()
            }
        }
        .task(id: id) {
            value = nil
            Task.detached {
                let value = closure()
                await MainActor.run {
                    self.value = value
                }
            }
        }
    }
}

//     public init<F>(_ titleKey: LocalizedStringKey, value: F.FormatInput, format: F) where F : FormatStyle, F.FormatInput : Equatable, F.FormatOutput == String

extension TaskView where Content == LabeledContent<Text, Text> {
    init(id: ID, _ titleKey: LocalizedStringKey, closure: @Sendable @escaping () -> Value) {
        self.init(id: id, closure: closure) { value in
            LabeledContent(titleKey, value: "\(value)")
        }
    }
}

func computeLowHangingFruitSize(splats: [SplatB]) -> Int {
    //    public var position: PackedFloat3    = 3 * 10
    //    public var scale: PackedFloat3       = 3 * 10
    //    public var color: SIMD4<UInt8>       = 20 (5/6/5/4)
    //    public var rotation: SIMD4<UInt8>    = 32
    let splatSize: Double = (3 * 12 + 3 * 12 + 20 + 28)
    //    print(splatSize / 8)

    return Int(ceil(splatSize / 8)) * splats.count
}
