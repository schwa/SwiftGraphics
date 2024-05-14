#if !os(visionOS)
import Algorithms
import AsyncAlgorithms
import CoreGraphicsSupport
import CoreImage
import Everything
import Metal
import MetalKit
import ModelIO
import Observation
import RenderKit
import SIMDSupport
import SwiftFields
import SwiftFormats
import SwiftUI
import UniformTypeIdentifiers

struct CoreSimpleSceneView: View {
    @Environment(\.metalDevice)
    var device

    @Binding
    var scene: SimpleScene

    @State
    var renderPass: SimpleSceneRenderPass

    init(scene: Binding<SimpleScene>) {
        _scene = scene
        let sceneRenderPass = SimpleSceneRenderPass(scene: scene.wrappedValue)
        renderPass = sceneRenderPass
    }

    var body: some View {
        RendererView(renderPass: $renderPass)
            .onChange(of: scene.camera) {
                renderPass.scene = scene
            }
            .onChange(of: scene.light) {
                renderPass.scene = scene
            }
            .onChange(of: scene.ambientLightColor) {
                renderPass.scene = scene
            }
    }
}

// MARK: -

struct SimpleSceneDemoView: View, DemoView {
    @Environment(\.metalDevice)
    var device

    @State
    var scene: SimpleScene

    #if os(macOS)
        @State
        var isInspectorPresented = true
    #else
        @State
        var isInspectorPresented = false
    #endif

    @State
    var exportImage: Image?

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        scene = try! SimpleScene.demo(device: device)
    }

    var body: some View {
        CoreSimpleSceneView(scene: $scene)
        #if os(macOS)
        .firstPersonInteractive(camera: $scene.camera)
        .displayLink(DisplayLink2())
        .showFrameEditor()
        #endif
        .overlay(alignment: .bottomTrailing, content: mapView)
        .inspector(isPresented: $isInspectorPresented, content: inspector)
    }

    func mapView() -> some View {
        SimpleSceneMapView(scene: $scene)
            .border(Color.red)
            .frame(width: 200, height: 200)
            .padding()
    }

    func inspector() -> some View {
        MyTabView(scene: $scene)
            .inspectorColumnWidth(ideal: 300)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(title: "Show/Hide Inspector", systemImage: "sidebar.trailing") {
                        isInspectorPresented.toggle()
                    }
                }
            }
    }
}

// MARK: -

struct MyTabView: View {
    enum Tab: Hashable {
        case inspector
        case counters
    }

    @State
    var tab: Tab = .inspector

    @Binding
    var scene: SimpleScene

    var body: some View {
        VStack {
            Picker("Picker", selection: $tab) {
                Image(systemName: "slider.horizontal.3").tag(Tab.inspector)
                Image(systemName: "tablecells").tag(Tab.counters)
            }
            .labelsHidden()
            .fixedSize()
            .pickerStyle(.palette)
            Divider()
            switch tab {
            case .inspector:
                Group {
                    SimpleSceneInspector(scene: $scene)
                        .controlSize(.small)
                }
            case .counters:
                CountersView()
            }
        }
    }
}
#endif
