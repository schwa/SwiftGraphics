import Everything
import GaussianSplatDemos
import os
import SwiftUI
import SwiftUISupport

public struct DemosScene: Scene {
    public init() {
    }

    public var body: some Scene {
#if os(macOS)
        Window("Demos", id: "demos") {
            DemosView()
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
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

struct Demo: Hashable {
    var type: any DemoView.Type

    init <T>(_ type: T.Type) where T: DemoView {
        self.type = type
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        ObjectIdentifier(lhs.type) == ObjectIdentifier(rhs.type)
    }

    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(type).hash(into: &hasher)
    }

    var name: String {
        String(describing: type).replacingOccurrences(of: "DemoView", with: "").replacing(#/[A-Z][^A-Z]+/#) { match in
            String(match.output) + " "
        }.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct DemosView: View {
    @State
    private var currentDemo: Demo?

    var body: some View {
        NavigationSplitView {
            List(selection: $currentDemo) {
                row(for: GaussianSplatMinimalView.self)
                row(for: GaussianSplatView.self)
                row(for: SplatCloudInfoView.self)
                row(for: SingleSplatView.self)
                row(for: SimplePBRSceneGraphDemoView.self)
                row(for: TriangleReflectionView.self)
                row(for: QuasiRandomTriangleView.self)
                row(for: PointCloudView.self)
                row(for: PointCloudSoftwareRenderView.self)
                group(named: "Current") {
                    row(for: HalfEdge3DDemoView.self)
                    row(for: HalfEdge2DDemoView.self)
                }
                group(named: "RenderKit") {
                    row(for: SceneGraphDemoView.self)
                    row(for: VolumetricRendererDemoView.self)
                }
                group(named: "Software Renderers") {
                    row(for: SoftwareRendererBoxesDemoView.self)
                    row(for: SoftwareRendererMeshDemoView.self)
                }
                group(named: "Unorganized") {
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
                row(for: FieldsTestBedView.self)
            }
        } detail: {
            ZStack {
                if let currentDemo {
                    AnyView(currentDemo.type.init())//.id(currentDemo)
                }
            }
            .logger(Logger())
            .inlineNotificationOverlay()
        }
    }

    @ViewBuilder
    func row(for type: any DemoView.Type) -> some View {
        let demo = Demo(type)
        NavigationLink(value: demo) {
            Label(demo.name, systemImage: "puzzlepiece")
                .truncationMode(.tail)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    func group<Content>(named name: String, @ViewBuilder content: () -> Content) -> some View where Content: View {
        let content = content()
        ValueView(value: true) { isExpanded in
            DisclosureGroup(isExpanded: isExpanded) {
                content
            } label: {
                Label(name, systemImage: "folder")
                    .truncationMode(.tail)
                    .lineLimit(1)
            }
        }
    }
}
