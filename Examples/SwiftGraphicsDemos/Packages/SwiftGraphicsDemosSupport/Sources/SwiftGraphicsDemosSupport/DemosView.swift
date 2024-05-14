import SwiftUI

struct DemosView: View {
    var demos: [any DefaultInitializableView.Type] = [
        BeziersView.self,
        LineDemoView.self,
        HobbyCurveView.self,
        ShaderTestView.self,
        CustomStrokeEditor.self,
        SplineDemoView.self,
        AngleDemoView.self,
        BoxesView.self,
        HalfEdgeView.self,
        MeshView.self,
        VolumetricView.self,
        SimpleSceneView.self,
        CSGDemoView.self,
        SimulationView.self,
        Particles2View.self,
    ]

    var body: some View {
        NavigationView {
            List(demos.indexed(), id: \.index) { _, element in
                NavigationLink(String(describing: element)) {
                    AnyView(element.init())
                }
            }
        }
    }
}
