import RenderKitSceneGraph
import Testing

@Test
func test1() {
    let node = Node {
        Node(label: "A")
        Node(label: "B")
        Node(label: "C")
    }
    #expect(node.firstNode(label: "B") != nil)
}
