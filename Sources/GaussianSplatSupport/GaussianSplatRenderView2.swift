import CoreGraphicsSupport
import MetalKit
import MetalSupport
import RenderKit
import simd
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

struct NodeAccessor {
    var path: IndexPath
}

extension SceneGraph {
    func accessor(for label: String) -> NodeAccessor? {
        guard let path = root.allIndexedNodes().first(where: { $0.node.label == label })?.path else {
            return nil
        }
        return .init(path: path)
    }

    subscript(accessor accessor: NodeAccessor) -> Node? {
        get {
            root[indexPath: accessor.path]
        }
        set {
            // TODO: FIXME
            root[indexPath: accessor.path] = newValue!
        }
    }

    mutating func modify <R>(label: String, _ block: (inout Node?) throws -> R) rethrows -> R {
        guard let accessor = accessor(for: label) else {
            fatalError()
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    mutating func modify <R>(accessor: NodeAccessor, _ block: (inout Node?) throws -> R) rethrows -> R {
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }
}

public struct GaussianSplatRenderView2: View {
    @State
    private var device: MTLDevice

    @Environment(GaussianSplatViewModel.self)
    var viewModel

    @State
    var scene: SceneGraph

    public init(device: MTLDevice) {
        self.device = device

        let root = try! Node(label: "root") {
            Node(label: "camera").content(Camera())
            Node(label: "splats")
        }
        self.scene = SceneGraph(root: root)
    }

    public var body: some View {
        RenderView(device: device, passes: passes)
        .onChange(of: viewModel.splats) {
            scene.modify(label: "splats") {
                $0!.content = viewModel.splats
            }
        }
    }

    var passes: [any PassProtocol] {
        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splats: viewModel.splats,
            modelMatrix: simd_float3x3(truncating: viewModel.modelTransform.matrix),
            cameraPosition: viewModel.cameraTransform.translation
        )

        let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
            splats: viewModel.splats,
            sortRate: viewModel.sortRate
        )

        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            cameraTransform: viewModel.cameraTransform,
            cameraProjection: viewModel.cameraProjection,
            modelTransform: viewModel.modelTransform,
            splats: viewModel.splats,
            debugMode: viewModel.debugMode
        )

        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
    }
}
