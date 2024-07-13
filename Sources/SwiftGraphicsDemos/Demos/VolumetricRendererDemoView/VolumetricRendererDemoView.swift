#if !os(visionOS)
import CoreGraphicsSupport
import Metal
import MetalKit
import MetalSupport
import ModelIO
import os
import RenderKit
import RenderKitShadersLegacy
import RenderKitUISupport
import Shapes2D
import SIMDSupport
import SwiftUI

// https://www.youtube.com/watch?v=y4KdxaMC69w&t=1761s

struct VolumetricRendererDemoView: DemoView {
    @State
    var redTransferFunction: [Float] = Array(repeating: 1.0, count: 256)

    @State
    var greenTransferFunction: [Float] = Array(repeating: 1.0, count: 256)

    @State
    var blueTransferFunction: [Float] = Array(repeating: 1.0, count: 256)

    @State
    var alphaTransferFunction: [Float] = (0 ..< 256).map { Float($0) / Float(255) }

    let device = MTLCreateSystemDefaultDevice()!

    @State
    var scene: SceneGraph = .basicScene

    init() {
    }

    var body: some View {
        let renderPasses = [VolumetricRenderPass(scene: scene)]
        RenderView(passes: renderPasses)
            .onAppear {
                let volumeData = try! VolumeData(named: "CThead", in: Bundle.module, size: MTLSize(256, 256, 113))
                let volumeRepresentation = try! VolumeRepresentation(device: device, volumeData: volumeData)

                var scene = SceneGraph.basicScene
                let node = Node(label: "volume", content: volumeRepresentation)
                scene.root.children.append(node)
                updateTransferFunctionTexture(&scene)
                self.scene = scene
            }
            .onChange(of: redTransferFunction) {
                updateTransferFunctionTexture(&scene)
            }
            .onChange(of: greenTransferFunction) {
                updateTransferFunctionTexture(&scene)
            }
            .onChange(of: blueTransferFunction) {
                updateTransferFunctionTexture(&scene)
            }
            .onChange(of: alphaTransferFunction) {
                updateTransferFunctionTexture(&scene)
            }
            .overlay(alignment: .bottom) {
                VStack {
                    TransferFunctionSingleChannelEditor(width: 1_024, values: $redTransferFunction, color: .red)
                        .frame(maxHeight: 20)
                    TransferFunctionSingleChannelEditor(width: 1_024, values: $greenTransferFunction, color: .green)
                        .frame(maxHeight: 20)
                    TransferFunctionSingleChannelEditor(width: 1_024, values: $blueTransferFunction, color: .blue)
                        .frame(maxHeight: 20)
                    TransferFunctionSingleChannelEditor(width: 1_024, values: $alphaTransferFunction, color: .white)
                        .frame(maxHeight: 20)
                }
                .frame(maxWidth: 320)
                .background(.ultraThinMaterial)
                .padding()
                .controlSize(.small)
            }
            .modifier(SceneGraphViewModifier(scene: $scene))
    }

    func updateTransferFunctionTexture(_ scene: inout SceneGraph) {
        let values = (0 ... 255).map { value in
            SIMD4<Float>(
                redTransferFunction[value],
                greenTransferFunction[value],
                blueTransferFunction[value],
                alphaTransferFunction[value]
            )
        }
        .map { $0 * 255.0 }
        .map { SIMD4<UInt8>($0) }

        values.withUnsafeBytes { buffer in
            guard scene.node(for: "volume") != nil else {
                return
            }

            let region = MTLRegion(origin: [0, 0, 0], size: [256, 1, 1]) // TODO: Hardcoded
            let bytesPerRow = 256 * MemoryLayout<SIMD4<UInt8>>.stride
            scene.modify(label: "volume") { node in
                let volumeRepresentation = node!.content as! VolumeRepresentation
                volumeRepresentation.transferFunctionTexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: buffer.baseAddress!, bytesPerRow: bytesPerRow, bytesPerImage: 0)
                node!.content = volumeRepresentation
            }
        }
    }
}

struct TransferFunctionSingleChannelEditor: View {
    let width: Int

    @Binding
    var values: [Float]

    let color: Color

    @State
    private var lastLocation: CGPoint?

    let coordinateSpace = NamedCoordinateSpace.named(ObjectIdentifier(Self.self))

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                context.scaleBy(x: 1, y: -1)
                context.translateBy(x: 0, y: -size.height)
                context.scaleBy(x: size.width / Double(values.count), y: 1)
                let path = Path { path in
                    path.move(to: .zero)
                    for (index, value) in values.enumerated() {
                        path.addLine(to: CGPoint(Double(index), Double(value) * size.height))
                    }
                    path.addLine(to: CGPoint(x: 1_023, y: 0))
                    path.closeSubpath()
                }
                context.fill(path, with: .color(color))
            }
            .coordinateSpace(coordinateSpace)
            .gesture(gesture(proxy.size))
        }
        .contextMenu {
            Button("Clear") {
                values = Array(repeating: 0, count: values.count)
            }
            Button("Set") {
                values = Array(repeating: 1, count: values.count)
            }
            Button("Ramp Up") {
                values = (0 ..< values.count).map { Float($0) / Float(values.count) }
            }
            Button("Ramp Down") {
                values = (0 ..< values.count).map { 1 - Float($0) / Float(values.count) }
            }
        }
    }

    func gesture(_ size: CGSize) -> some Gesture {
        DragGesture(coordinateSpace: coordinateSpace)
            .onChanged { value in
                let count = values.count
                let startColumn = clamp(Int((lastLocation ?? value.location).x * Double(count - 1) / size.width), in: 0 ... (count - 1))
                let endColumn = clamp(Int(value.location.x * Double(values.count - 1) / size.width), in: 0 ... (values.count - 1))
                let v = clamp(1 - Float(value.location.y / size.height), in: 0 ... 1)
                for column in stride(from: startColumn, through: endColumn, by: endColumn >= startColumn ? 1 : -1) {
                    values[column] = v
                }
                lastLocation = value.location
            }
            .onEnded { _ in
                lastLocation = nil
            }
    }
}
#endif
