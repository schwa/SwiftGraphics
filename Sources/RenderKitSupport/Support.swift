import RenderKit
import SwiftGraphicsSupport

public extension SceneGraph {
    static let basicScene = SceneGraph(root: Node(label: "Root", children: [
        Node(label: "camera", content: Camera())
    ]))
}
