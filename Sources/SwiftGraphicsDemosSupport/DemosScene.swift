import Everything
import SwiftUI

public struct DemosScene: Scene {
    public init() {
        print(Bundle.module)
    }

    public var body: some Scene {
#if os(macOS)
        Window("Demos", id: "demos") {
            DemosView()
        }
#else
        WindowGroup("Demos", id: "demos") {
            DemosView()
        }
#endif
    }
}

protocol DemoView: View {
    @MainActor init()
}

struct DemosView: View {
    var body: some View {
        NavigationView {
            List {
                row(for: PointCloudView.self)
                row(for: PointCloudSoftwareRenderView.self)
                ValueView(value: true) { isExpanded in
                    DisclosureGroup("Current", isExpanded: isExpanded) {
                        row(for: HalfEdge3DDemoView.self)
                        row(for: HalfEdge2DDemoView.self)
                    }
                }
                ValueView(value: true) { isExpanded in
                    DisclosureGroup("RenderKit", isExpanded: isExpanded) {
                        row(for: SceneGraphDemoView.self)
                        row(for: VolumetricRendererDemoView.self)
                    }
                }
                Divider()
                ValueView(value: true) { isExpanded in
                    DisclosureGroup("Software Renderers", isExpanded: isExpanded) {
                        row(for: SoftwareRendererBoxesDemoView.self)
                        row(for: SoftwareRendererMeshDemoView.self)
                    }
                }
                ValueView(value: true) { isExpanded in
                    DisclosureGroup("Unorganized", isExpanded: isExpanded) {
                        row(for: TextureDemoView.self)
                        row(for: ShaderTestDemoView.self)
                        row(for: Particles2DemoView.self)
                        row(for: AngleDemoView.self)
                        row(for: BeziersDemoView.self)
                        row(for: CSGDemoView.self)
                        row(for: CustomStrokeEditorDemoView.self)
                        row(for: HobbyCurveDemoView.self)
                        row(for: LineDemoView.self)
                        row(for: PixelFormatsDemoView.self)
                        row(for: ShapesDemoView.self)
                        row(for: SimulationDemoView.self)
                        row(for: SketchDemoView.self)
                        row(for: SplineDemoView.self)
                    }
                }
            }
        }
    }

    func row(for type: any DemoView.Type) -> some View {
        NavigationLink(name(for: type)) {
            LazyView { AnyView(type.init()).id(String(describing: type)) }
        }
    }

    func name(for type: any DemoView.Type) -> String {
        String(describing: type).replacingOccurrences(of: "DemoView", with: "").replacing(#/[A-Z][^A-Z]+/#) { match in
            String(match.output) + " "
        }.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
