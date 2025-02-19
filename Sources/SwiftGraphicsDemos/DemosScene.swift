import BaseSupport
import Everything
import GaussianSplatSupport
import os
import SwiftUI
import SwiftUISupport

public struct DemosScene: Scene {
    @AppStorage("Logging")
    var logging: Bool = true

    public init() {
    }

    public var body: some Scene {
        #if os(macOS)
        Window("Demos", id: "demos") {
            DemosView()
                .logger(logging ? Logger(subsystem: "Demos", category: "Demos") : nil)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
        }

        Settings {
            SettingsView()
        }

        #else
        WindowGroup("Demos", id: "demos") {
            DemosView()
                .logger(Logger())
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
    //    @CodableAppStorage("CurrentDemo")
    private var currentDemo: Demo?

    var body: some View {
        NavigationSplitView {
            List(selection: $currentDemo) {
                row(for: GaussianSplatAntimatter15DemoView.self)
                row(for: SplatsEditorDemo.self)
                row(for: SingleSplatView.self)
                //                row(for: GaussianSplatLobbyView.self)
                row(for: LineGeometryShaderView.self)
                row(for: CustomStrokeEditorDemoView.self)
                row(for: CameraControllerDemo.self)
                group(named: "RenderKit") {
                    // TODO: All failing right now
                    row(for: PointCloudView.self)
                    row(for: SceneGraphDemoView.self)
                    row(for: SimplePBRSceneGraphDemoView.self)
                    row(for: VolumetricRendererDemoView.self)
                }
                group(named: "Software Renderers") {
                    row(for: SoftwareRendererBoxesDemoView.self)
                    row(for: SoftwareRendererMeshDemoView.self)
                    row(for: PointCloudSoftwareRenderView.self)
                }
                group(named: "SwiftUI Shaders", disclosed: true) {
                    row(for: SwiftUIShaderDemoView.self)
                    row(for: SignedDistanceFieldsDemoView.self)
                }
                group(named: "UI", disclosed: false) {
                    row(for: CountersDemoView.self)
                    row(for: FieldsTestBedView.self)
                    row(for: InlineNotificationsDemoView.self)
                }
                group(named: "Unorganized", disclosed: false) {
                    row(for: AngleDemoView.self)
                    row(for: BeziersDemoView.self)
                    row(for: HobbyCurveDemoView.self)
                    row(for: PixelFormatsDemoView.self)
                    row(for: Particles2DemoView.self)
                    row(for: QuasiRandomTriangleView.self)
                    row(for: ShapesDemoView.self)
                    row(for: SimulationDemoView.self)
                    row(for: SketchDemoView.self)
                    row(for: SplineDemoView.self)
                    row(for: TriangleReflectionView.self)
                    row(for: LineDemoView.self)
                }
                group(named: "Failing", disclosed: false) {
                    row(for: CSGDemoView.self)  // TODO: Broken
                    row(for: LineDemoView.self) // TODO: Broken
                }
            }
        } detail: {
            ZStack {
                if let currentDemo {
                    AnyView(currentDemo.type.init())// .id(currentDemo)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    func group<Content>(named name: String, disclosed: Bool = true, @ViewBuilder content: () -> Content) -> some View where Content: View {
        let content = content()
        ValueView(value: disclosed) { isExpanded in
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

struct SettingsView: View {
    @AppStorage("Logging")
    var logging: Bool = true

    var body: some View {
        Form {
            Toggle(isOn: $logging) {
                Text("Logging")
            }
        }
        .frame(minWidth: 320, minHeight: 240)
    }
}

extension GaussianSplatAntimatter15DemoView: DemoView {
}

extension SingleSplatView: DemoView {
}
