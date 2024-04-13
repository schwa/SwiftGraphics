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
        HobbyView.self,
        ShaderTestView.self,
        CustomStrokeEditor.self,
        SplineDemoView.self,
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

extension HobbyView: DefaultInitializableView {
}

extension ShaderTestView: DefaultInitializableView {
}

extension CustomStrokeEditor: DefaultInitializableView {
}
