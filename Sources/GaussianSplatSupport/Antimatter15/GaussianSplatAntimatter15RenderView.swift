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
        //        let url = Bundle.main.url(forResource: "ThreeSplats", withExtension: "json")!
        let url = Bundle.main.url(forResource: "centered_lastchance", withExtension: "splat")!
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
        return splats
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
    private var flipModel: Bool = true

    @State
    private var reversedSort: Bool = false

    @State
    private var isInspectorPresented = false

    @State
    private var ballControllerDebug = false

    @MainActor
    public init(splatCloud: SplatCloud<SplatX>) {
        self.splatCloud = splatCloud
        let perspectiveProjection = PerspectiveProjection(verticalAngleOfView: .degrees(75), zClip: 0.2 ... 200)
        configuration = GaussianSplatAntimatter15RenderPass.Configuration(modelMatrix: .identity, cameraMatrix: .identity, projection: perspectiveProjection, debugMode: .off)
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
        .onChange(of: flipModel, initial: true) {
            if !flipModel {
                configuration.modelMatrix = .identity
            }
            else {
                configuration.modelMatrix = simd_float4x4(columns: (
                    [1.0, 0.0, 0.0, 0.0],
                    [0.0, -1.0, 0.0, 0.0],
                    [0.0, 0.0, -1.0, 0.0],
                    [0.0, 0.0, 0.0, 1.0]
                ))
            }
            requestSort()
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

                Picker("Debug Mode", selection: $configuration.debugMode) {
                    ForEach(GaussianSplatAntimatter15RenderPass.Configuration.DebugMode.allCases, id: \.self) { mode in
                        Text("\(mode)").tag(mode)
                    }
                }
                Toggle("flip", isOn: $flipModel)
                Toggle("Ball Controller Debug", isOn: $ballControllerDebug)

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

                TextField("Splat Scale", value: $configuration.splatScale, format: .number.precision(.fractionLength(0...3)))

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

struct GaussianSplatAntimatter15RenderPass: RenderPassProtocol {
    @MetalBindings(function: .vertex)
    struct VertexBindings {
        var splats: Int = -1
        var indexedDistances: Int = -1
        var modelMatrix: Int = -1
        var viewMatrix: Int = -1
        var projectionMatrix: Int = -1
        var drawableSize: Int = -1
        var splatScale: Int = -1
    }

    struct State {
        var vertexBindings: VertexBindings
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    struct Configuration: Equatable {
        enum DebugMode: Int32, CaseIterable {
            case off = 0
            case wireframe = 1
            case filled = 2
        }

        var modelMatrix: simd_float4x4
        var cameraMatrix: simd_float4x4
        var projection: PerspectiveProjection
        var debugMode: DebugMode
        var splatScale: Float = 1.0
        //        var blendConfiguration: BlendConfiguration = .init(
        //            sourceRGBBlendFactor: .sourceAlpha,
        //            destinationRGBBlendFactor: .oneMinusSourceAlpha,
        //            rgbBlendOperation: .add,
        //            sourceAlphaBlendFactor: .sourceAlpha,
        //            destinationAlphaBlendFactor: .oneMinusSourceAlpha,
        //            alphaBlendOperation: .add
        //        )
        var blendConfiguration: BlendConfiguration = .init(
            sourceRGBBlendFactor: .one,
            destinationRGBBlendFactor: .oneMinusSourceAlpha,
            rgbBlendOperation: .add,
            sourceAlphaBlendFactor: .one,
            destinationAlphaBlendFactor: .oneMinusSourceAlpha,
            alphaBlendOperation: .add
        )
    }

    struct BlendConfiguration: Hashable {
        var sourceRGBBlendFactor: MTLBlendFactor
        var destinationRGBBlendFactor: MTLBlendFactor
        var rgbBlendOperation: MTLBlendOperation
        var sourceAlphaBlendFactor: MTLBlendFactor
        var destinationAlphaBlendFactor: MTLBlendFactor
        var alphaBlendOperation: MTLBlendOperation
    }

    var id: PassID
    var splatCloud: SplatCloud<SplatX>
    var configuration: Configuration

    func setup(device: any MTLDevice, configuration: some RenderKit.MetalConfigurationProtocol) throws -> State {
        guard let bundle = Bundle.main.bundle(forTarget: "GaussianSplatShaders") else {
            throw BaseError.error(.missingResource)
        }
        let library = try device.makeDebugLibrary(bundle: bundle)
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor(configuration)
        renderPipelineDescriptor.label = "\(type(of: self))"

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride

        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        // TODO: Magic constant
        let constantValues = MTLFunctionConstantValues(dictionary: [2: self.configuration.debugMode.rawValue])

        renderPipelineDescriptor.vertexFunction = try library.makeFunction(name: "GaussianSplatAntimatter15RenderShaders::vertexMain", constantValues: constantValues)
        renderPipelineDescriptor.fragmentFunction = try library.makeFunction(name: "GaussianSplatAntimatter15RenderShaders::fragmentMain", constantValues: constantValues)

        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = self.configuration.blendConfiguration.rgbBlendOperation
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = self.configuration.blendConfiguration.alphaBlendOperation

        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = self.configuration.blendConfiguration.sourceRGBBlendFactor
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = self.configuration.blendConfiguration.sourceAlphaBlendFactor

        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = self.configuration.blendConfiguration.destinationRGBBlendFactor
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = self.configuration.blendConfiguration.destinationAlphaBlendFactor

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            throw BaseError.error(.resourceCreationFailure)
        }

        var vertexBindings = VertexBindings()
        try vertexBindings.updateBindings(with: reflection)

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .always, isDepthWriteEnabled: false)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)

        return State(vertexBindings: vertexBindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    func render(commandBuffer: any MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: RenderKit.PassInfo, state: State) throws {
        guard configuration.cameraMatrix != .zero else {
            print("Skipping pass - camera matrix is zero")
            return
        }
        let drawableSize = info.drawableSize
        //        print(drawableSize)
        let viewMatrix = configuration.cameraMatrix.inverse
        let modelMatrix = configuration.modelMatrix
        var projectionMatrix = configuration.projection.projectionMatrix(for: info.drawableSize)

        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))", useDebugGroup: true) { commandEncoder in
            if info.configuration.depthStencilPixelFormat != .invalid {
                commandEncoder.setDepthStencilState(state.depthStencilState)
            }
            commandEncoder.setRenderPipelineState(state.renderPipelineState)
            if configuration.debugMode == .wireframe {
                commandEncoder.setTriangleFillMode(.lines)
            }
            commandEncoder.withDebugGroup("VertexShader") {
                let vertices: [SIMD2<Float>] = [
                    [-1, -1], [-1, 1], [1, -1], [1, 1]
                ]
                commandEncoder.setVertexBytes(of: vertices, index: 0)
                commandEncoder.setVertexBuffer(splatCloud.splats.unsafeBase, offset: 0, index: state.vertexBindings.splats)
                commandEncoder.setVertexBuffer(splatCloud.indexedDistances.indices.unsafeBase, offset: 0, index: state.vertexBindings.indexedDistances)

                commandEncoder.setVertexBytes(of: modelMatrix, index: state.vertexBindings.modelMatrix)
                commandEncoder.setVertexBytes(of: viewMatrix, index: state.vertexBindings.viewMatrix)
                commandEncoder.setVertexBytes(of: projectionMatrix, index: state.vertexBindings.projectionMatrix)
                commandEncoder.setVertexBytes(of: drawableSize, index: state.vertexBindings.drawableSize)
                commandEncoder.setVertexBytes(of: configuration.splatScale, index: state.vertexBindings.splatScale)
            }
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: splatCloud.splats.count)
        }
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
