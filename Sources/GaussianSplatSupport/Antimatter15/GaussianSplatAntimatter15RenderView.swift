import BaseSupport
import CoreGraphicsSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import os
import RenderKit
import simd
import SIMDSupport
import Spatial
import SwiftUI
import UniformTypeIdentifiers
import Widgets3D

extension UTType {
    static let splat = UTType(filenameExtension: "splat")!
    static let splatX = UTType(filenameExtension: "splatx")!
}

// MARK: -

public struct GaussianSplatAntimatter15DemoView: View {
    @State
    private var splatCloud: SplatCloud<SplatX>

    @State
    private var isDropTargeted = false

    public init() {
        let url = Bundle.main.url(forResource: "centered_lastchance", withExtension: "splat")!
//        let url = Bundle.main.url(forResource: "1Splat", withExtension: "json")!
        let splatCloud = try! SplatCloud<SplatX>(device: MTLCreateSystemDefaultDevice()!, url: url)
        splatCloud.label = "\(url.lastPathComponent)"
        self.splatCloud = splatCloud
    }

    public var body: some View {
        GaussianSplatAntimatter15RenderView(splatCloud: splatCloud)
            .onDrop(of: [.splat, .json], isTargeted: $isDropTargeted) { providers in
                guard let provider = providers.first else {
                    return false
                }
                Task {
                    guard let url = try! await provider.loadItem(forTypeIdentifier: UTType.item.identifier, options: nil) as? URL else {
                        return
                    }
                    let splatCloud = try! SplatCloud<SplatX>(device: MTLCreateSystemDefaultDevice()!, url: url)
                    splatCloud.label = "\(url)"
                    await MainActor.run {
                        self.splatCloud = splatCloud
                    }
                }
                return true
            }
            .toolbar {
                Menu("Load") {
                    ForEach(allSplats(), id: \.self) { url in
                        Button("Load \(url.lastPathComponent)") {
                            let splatCloud = try! SplatCloud<SplatX>(device: MTLCreateSystemDefaultDevice()!, url: url)
                            splatCloud.label = "\(url.lastPathComponent)"
                            self.splatCloud = splatCloud
                        }
                    }
                }
            }
    }

    func allSplats() -> [URL] {
        let bundleURL = Bundle.main.resourceURL!
        var splats: [URL] = []
        let enumerator = FileManager().enumerator(at: bundleURL, includingPropertiesForKeys: nil)!
        for element in enumerator {
            let url = element as! URL
            if url.pathExtension == "splat" || url.pathExtension == "json" {
                splats.append(url)
            }
        }
        return splats.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}

// MARK: -

public struct GaussianSplatAntimatter15RenderView: View {
    enum Controller {
        case ball
        case gameController
    }

    private let splatCloud: SplatCloud<SplatX>

    @State
    private var sortManager: AsyncSortManager<SplatX>?

    @State
    private var configuration: GaussianSplatAntimatter15RenderPass.Configuration

    @State
    private var controller = Controller.ball

    @State
    private var size: CGSize = .zero

    @State
    private var currentSortState: SortState?

    @Environment(\.displayScale)
    private var displayScale

    @State
    private var reversedSort: Bool = false

    @State
    private var isInspectorPresented = false

    @State
    private var ballControllerDebug = false

    @MainActor
    public init(splatCloud: SplatCloud<SplatX>) {
        self.splatCloud = splatCloud
        let modelMatrix = simd_float4x4(columns: (
            .init(1.0, 0.0, 0.0, 0.0),
            .init(0.0, 1.0, 0.0, 0.0),
            .init(0.0, 0.0, 1.0, 0.0),
            .init(0.0, 0.0, 0.0, 1.0)
        ))
        let perspectiveProjection = PerspectiveProjection(verticalAngleOfView: .degrees(75), zClip: 0.2 ... 200)
        configuration = GaussianSplatAntimatter15RenderPass.Configuration(modelMatrix: modelMatrix, cameraMatrix: .identity, projection: perspectiveProjection, debugMode: .off)
    }

    public var body: some View {
        RenderView(pass: pass) { configuration in
            configuration.colorPixelFormat = .bgra8Unorm
        }
        .toolbar {
            Toggle("Inspector", isOn: $isInspectorPresented)
        }
        .onChange(of: splatCloud, initial: true) {
            sortManager = try! AsyncSortManager(device: MTLCreateSystemDefaultDevice()!, splatCloud: splatCloud, capacity: splatCloud.capacity, logger: Logger())
            Task {
                let channel = await sortManager!.sortedIndicesChannel()
                for await sort in channel {
                    pass.splatCloud.indexedDistances = sort
                    MainActor.runTask {
                        currentSortState = sort.state
                        print("Setting current sort state to \(sort.state.shortDescription)")
                    }
                }
            }
        }
        .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
        .onChange(of: configuration.cameraMatrix) {
            requestSort()
        }
        .onChange(of: configuration.modelMatrix) {
            requestSort()
        }
        .onChange(of: reversedSort) {
            requestSort()
        }
        .onChange(of: splatCloud) {
            requestSort()
        }
        .modifier(NewBallControllerViewModifier(constraint: .init(radius: 2), transform: $configuration.cameraMatrix, debug: ballControllerDebug))
        //        .modifier(GameControllerModifier(cameraMatrix: $configuration.cameraMatrix))
        .inspector(isPresented: $isInspectorPresented) {
            Form {
                Text("\(splatCloud.label ?? "")")
                Text("\(splatCloud.count) splats")
                Toggle("Reversed Sort", isOn: $reversedSort)
                Toggle("Ball Controller Debug", isOn: $ballControllerDebug)
//
//                LabeledContent("Distance") {
//                    VStack {
//                        TextField("Distance", value: $configuration.maxDistance, format: .number.precision(.fractionLength(0...3)))
//                        Slider(value: $configuration.maxDistance, in: 0...4)
//                    }
//                }

                Picker("Debug Mode", selection: $configuration.debugMode) {
                    ForEach(GaussianSplatAntimatter15RenderPass.Configuration.DebugMode.allCases, id: \.self) { mode in
                        Text("\(mode)").tag(mode)
                    }
                }

                DisclosureGroup("Sort State") {
                    LabeledContent("Current Sort State") {
                        if let currentSortState {
                            Text("\(currentSortState.shortDescription)")
                        }
                    }

                    LabeledContent("Theoretical Sort State") {
                        let state = SortState(camera: pass.configuration.cameraMatrix, model: configuration.modelMatrix, reversed: reversedSort, count: splatCloud.count)
                        Text("\(state.shortDescription)")
                    }
                }

                VStack {
                    TextField("Splat Scale", value: $configuration.splatScale, format: .number.precision(.fractionLength(0...3)))
                    Slider(value: $configuration.splatScale, in: 0.1...10)
                }

                DisclosureGroup("Blend") {
                    Picker("Source RGB Blend Factor", selection: $configuration.blendConfiguration.sourceRGBBlendFactor) {
                        ForEach(MTLBlendFactor.allCases, id: \.self) { factor in
                            Text("\(factor)")
                                .tag(factor)
                        }
                    }
                    Picker("Destination RGB Blend Factor", selection: $configuration.blendConfiguration.destinationRGBBlendFactor) {
                        ForEach(MTLBlendFactor.allCases, id: \.self) { factor in
                            Text("\(factor)")
                                .tag(factor)
                        }
                    }
                    Picker("RGB Blend Operation", selection: $configuration.blendConfiguration.rgbBlendOperation) {
                        ForEach(MTLBlendOperation.allCases, id: \.self) { operation in
                            Text("\(operation)")
                                .tag(operation)
                        }
                    }

                    Picker("Source Alpha Blend Factor", selection: $configuration.blendConfiguration.sourceAlphaBlendFactor) {
                        ForEach(MTLBlendFactor.allCases, id: \.self) { factor in
                            Text("\(factor)")
                                .tag(factor)
                        }
                    }
                    Picker("Destination Alpha Blend Factor", selection: $configuration.blendConfiguration.destinationAlphaBlendFactor) {
                        ForEach(MTLBlendFactor.allCases, id: \.self) { factor in
                            Text("\(factor)")
                                .tag(factor)
                        }
                    }
                    Picker("Alpha Blend Operation", selection: $configuration.blendConfiguration.alphaBlendOperation) {
                        ForEach(MTLBlendOperation.allCases, id: \.self) { operation in
                            Text("\(operation)")
                                .tag(operation)
                        }
                    }
                }
                DisclosureGroup("Projection") {
                    PerspectiveProjectionEditor(projection: $configuration.projection, size: size, displayScale: displayScale)
                        .controlSize(.mini)
                }

                DisclosureGroup("Camera") {
                    MatrixView(configuration.cameraMatrix)
                        .controlSize(.mini)
                }
                DisclosureGroup("View") {
                    MatrixView(configuration.cameraMatrix.inverse)
                        .controlSize(.mini)
                }
                DisclosureGroup("Model") {
                    MatrixView(configuration.modelMatrix)
                        .controlSize(.mini)
                }
            }
        }
    }

    private var pass: GaussianSplatAntimatter15RenderPass {
        .init(id: .init(CompositeHash("Antimatter15", configuration.debugMode, configuration.blendConfiguration)), splatCloud: splatCloud, configuration: configuration)
    }

    func requestSort() {
        sortManager!.requestSort(camera: pass.configuration.cameraMatrix, model: configuration.modelMatrix, reversed: reversedSort, count: splatCloud.count)
    }
}

// MARK: -

extension SplatCloud where Splat == SplatX {
    convenience init(device: MTLDevice, url: URL) throws {
        let data = try! Data(contentsOf: url)
        let splats: [SplatX]
        switch url.pathExtension {
        case "splat":
            splats = data.withUnsafeBytes { bytes in
                let splats = bytes.bindMemory(to: SplatB.self)
                return splats.map { SplatX($0) }
            }
        case "splatx":
            splats = data.withUnsafeBytes { bytes in
                let splats = bytes.bindMemory(to: SplatX.self)
                return Array(splats)
            }
        case "json":
            // JSON format is only useful for demo data.
            let splatds = try JSONDecoder().decode([SplatD].self, from: data)
            splats = splatds.map(SplatB.init).map(SplatX.init)
        default:
            fatalError("Unknown file extension")
        }
        try self.init(device: MTLCreateSystemDefaultDevice()!, splats: splats)
    }
}

extension MTLBlendOperation: @retroactive CaseIterable {
    public static let allCases: [MTLBlendOperation] = [.add, .subtract, .reverseSubtract, .min, .max]
}

extension MTLBlendOperation: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .add: return "add"
        case .subtract: return "subtract"
        case .reverseSubtract: return "reverseSubtract"
        case .min: return "min"
        case .max: return "max"
        @unknown default:
            fatalError("Unknown MTLBlendOperation")
        }
    }
}

extension MTLBlendFactor: @retroactive CaseIterable {
    public static let allCases: [MTLBlendFactor] = [.zero, .one, .sourceColor, .oneMinusSourceColor, .sourceAlpha, .oneMinusSourceAlpha, .destinationColor, .oneMinusDestinationColor, .destinationAlpha, .oneMinusDestinationAlpha, .sourceAlphaSaturated, .blendColor, .oneMinusBlendColor, .blendAlpha, .oneMinusBlendAlpha]
}

extension MTLBlendFactor: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .zero: return "zero"
        case .one: return "one"
        case .sourceColor: return "sourceColor"
        case .oneMinusSourceColor: return "oneMinusSourceColor"
        case .sourceAlpha: return "sourceAlpha"
        case .oneMinusSourceAlpha: return "oneMinusSourceAlpha"
        case .destinationColor: return "destinationColor"
        case .oneMinusDestinationColor: return "oneMinusDestinationColor"
        case .destinationAlpha: return "destinationAlpha"
        case .oneMinusDestinationAlpha: return "oneMinusDestinationAlpha"
        case .sourceAlphaSaturated: return "sourceAlphaSaturated"
        case .blendColor: return "blendColor"
        case .oneMinusBlendColor: return "oneMinusBlendColor"
        case .blendAlpha: return "blendAlpha"
        case .oneMinusBlendAlpha: return "oneMinusBlendAlpha"
        case .source1Color: return "source1Color"
        case .oneMinusSource1Color: return "oneMinusSource1Color"
        case .source1Alpha: return "source1Alpha"
        case .oneMinusSource1Alpha: return "oneMinusSource1Alpha"
        @unknown default:
            fatalError("Unknown MTLBlendFactor")
        }
    }
}

extension ClosedRange {
    var editableLowerBound: Bound {
        get {
            lowerBound
        }
        set {
            self = newValue ... upperBound
        }
    }
    var editableUpperBound: Bound {
        get {
            upperBound
        }
        set {
            self = lowerBound ... newValue
        }
    }
}

struct PerspectiveProjectionEditor: View {
    @Binding
    var projection: PerspectiveProjection

    let size: CGSize
    let displayScale: CGFloat

    @State
    private var userSize = SIMD2<Float>(1024, 768)

    var body: some View {
        TextField("Angle", value: $projection.verticalAngleOfView.degrees, format: .number)
        Slider(value: $projection.verticalAngleOfView.degrees, in: 0...360)

        TextField("Near", value: $projection.zClip.editableLowerBound, format: .number)
        TextField("Far", value: $projection.zClip.editableUpperBound, format: .number)

        //            let size = size * displayScale
        let projectionMatrix = projection.projectionMatrix(for: userSize)
        TextField("Width", value: $userSize.x, format: .number)
        TextField("Height", value: $userSize.y, format: .number)
        LabeledContent("PRojection") {
            MatrixView(projectionMatrix)
        }
    }
}
