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
    init()
}

struct DemosView: View {
    var demos: [any DemoView.Type] = [
        BeziersDemoView.self,
        LineDemoView.self,
        HobbyCurveDemoView.self,
        ShaderTestDemoView.self,
        CustomStrokeEditorDemoView.self,
        SplineDemoView.self,
        AngleDemoView.self,
        SoftwareRendererBoxesDemoView.self,
        HalfEdgeDemoView.self,
        SoftwareRendererMeshDemoView.self,
        VolumetricRendererDemoView.self,
        SimpleSceneDemoView.self,
        CSGDemoView.self,
        SimulationDemoView.self,
        Particles2DemoView.self,
        PixelFormatsDemoView.self,
        TextureDemoView.self,
        ShapesDemoView.self,
    ]

    var body: some View {
        NavigationView {
            List(demos.indexed(), id: \.index) { _, element in
                NavigationLink(name(for: element)) {
                    LazyView { AnyView(element.init()).id(String(describing: element)) }
                }
            }
        }
    }

    func name(for type: any DemoView.Type) -> String {
        String(describing: type).replacingOccurrences(of: "DemoView", with: "").replacing(#/[A-Z][^A-Z]+/#) { match in
            String(match.output) + " "
        }.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
