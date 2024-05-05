import SwiftUI

protocol DefaultInitializable {
    init()
}

protocol DefaultInitializableView: DefaultInitializable, View {
}

struct DemosView: View {
    var demos: [any DefaultInitializableView.Type] = [
        BeziersView.self,
        LineDemoView.self,
        HobbyCurveView.self,
        ShaderTestView.self,
        CustomStrokeEditor.self,
        SplineDemoView.self,
        AngleDemoView.self,
    ]

    var body: some View {
        NavigationView {
            List(demos.indexed(), id: \.index) { (index, element) in
                NavigationLink(String(describing: element)) {
                    AnyView(element.init())
                }
            }
        }
    }
}

extension BeziersView: DefaultInitializableView {
}

extension LineDemoView: DefaultInitializableView {
}

extension HobbyCurveView: DefaultInitializableView {
}

extension ShaderTestView: DefaultInitializableView {
}

extension CustomStrokeEditor: DefaultInitializableView {
}
