import Fields3D
import RenderKit
import SwiftUI

struct SceneGraphInspector: View {
    @Binding
    var scene: SceneGraph

    @State
    private var selection: Node.ID?

    var body: some View {
        VSplitView {
            List([scene.root], children: \.optionalChildren, selection: $selection) { node in
                if !node.label.isEmpty {
                    Text("Node: \"\(node.label)\"")
                }
                else {
                    Text("Node: <unnamed>")
                }
            }
            .frame(minHeight: 320)
            Group {
                if let selection, let indexPath = scene.firstIndexPath(id: selection) {
                    let node: Binding<Node> = $scene.binding(for: indexPath)
                    //                let node = scene.root[indexPath: indexPath]
                    List {
                        Form {
                            LabeledContent("ID", value: "\(node.wrappedValue.id)")
                            LabeledContent("Label", value: node.wrappedValue.label)
                            TransformEditor(node.transform)
                            VectorEditor(node.transform.translation)
                        }
                    }
                }
            }
            .frame(minHeight: 320)
        }
    }
}

extension Node {
    var optionalChildren: [Node]? {
        children.isEmpty ? nil : children
    }
}
