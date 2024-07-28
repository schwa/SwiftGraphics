import XCTest
import Testing
import SIMDSupport
@testable import RenderKitSceneGraph // Replace with the actual module name

struct NodeTests {
    @Test
    func testNodeInitialization() {
        let node = Node(label: "Test Node", transform: .identity, content: "Test Content", children: [])

        #expect(node.label == "Test Node")
        #expect(node.isEnabled == true)
        #expect(node.transform == .identity)
        #expect(node.content as? String == "Test Content")
        #expect(node.children.isEmpty)
    }

    @Test
    func testNodeEquality() {
        let node1 = Node(label: "Node 1")
        let node2 = Node(label: "Node 2")
        let node3 = Node(label: "Node 1")

        #expect(node1 == node1)
        #expect(node1 != node2)
        #expect(node1 != node3) // Different IDs, so not equal
    }

    @Test
    func testNodeGenerationIDUpdate() {
        var node = Node(label: "Test Node")
        let initialGenerationID = node.generationID

        node.label = "Updated Node"
        #expect(node.generationID != initialGenerationID)

        let secondGenerationID = node.generationID
        node.isEnabled = false
        #expect(node.generationID != secondGenerationID)
    }

    @Test
    func testNodeChildrenUpdate() {
        var parentNode = Node(label: "Parent")
        let initialGenerationID = parentNode.generationID

        let childNode = Node(label: "Child")
        parentNode.children.append(childNode)

        #expect(parentNode.generationID != initialGenerationID)
        #expect(parentNode.children.count == 1)
    }

    @Test
    func testNodeContentUpdate() {
        var node = Node(label: "Test Node")
        let initialChangeCount = node.changeCount

        node.content = "New Content"
        #expect(node.changeCount == initialChangeCount + 1)
        #expect(node.content as? String == "New Content")
    }

    @Test
    func testNodeDebugDescription() {
        let node = Node(label: "Test Node", content: 42, children: [Node(label: "Child")])
        let debugDescription = node.debugDescription

        #expect(debugDescription.contains("Test Node"))
        #expect(debugDescription.contains("42"))
        #expect(debugDescription.contains("Child"))
    }
}

struct NodeTests2 {
    @Test
    func testNodeInitialization() {
        let node = Node(label: "Test Node", transform: .identity, content: "Test Content" as String)
        #expect(node.label == "Test Node")
        #expect(node.transform == .identity)
        #expect(node.content as? String == "Test Content")
        #expect(node.children.isEmpty)
    }

    @Test
    func testNodeEquality() {
        let node1 = Node(label: "Node 1")
        let node2 = Node(label: "Node 2")
        #expect(node1 == node1)
        #expect(node1 != node2)
    }

    @Test
    func testNodeChangeCount() {
        var node = Node(label: "Test Node")
        let initialChangeCount = node.changeCount

        node.label = "Updated Label"
        #expect(node.changeCount == initialChangeCount + 1)

        node.transform = Transform(translation: [1, 0, 0])
        #expect(node.changeCount == initialChangeCount + 2)
    }
}

struct NodeBuilderTests {
    @Test
    func testSimpleNodeBuilding() {
        let root = Node {
            Node(label: "Child 1")
            Node(label: "Child 2")
        }

        #expect(root.children.count == 2)
        #expect(root.children[0].label == "Child 1")
        #expect(root.children[1].label == "Child 2")
    }

    @Test
    func testNestedNodeBuilding() {
        let root = Node {
            Node(label: "Child 1") {
                Node(label: "Grandchild 1")
                Node(label: "Grandchild 2")
            }
            Node(label: "Child 2")
        }

        #expect(root.children.count == 2)
        #expect(root.children[0].label == "Child 1")
        #expect(root.children[0].children.count == 2)
        #expect(root.children[0].children[0].label == "Grandchild 1")
        #expect(root.children[0].children[1].label == "Grandchild 2")
        #expect(root.children[1].label == "Child 2")
    }

    @Test
    func testNodeBuildingWithContent() {
        let root = Node {
            Node(label: "Child 1", content: 42 as Int)
            Node(label: "Child 2", content: "Hello" as String)
        }
        #expect(root.children.count == 2)
        #expect(root.children[0].content as? Int == 42)
        #expect(root.children[1].content as? String == "Hello")
    }

    @Test
    func testNodeBuildingWithTransform() {
        let root = Node {
            Node(label: "Child 1", transform: Transform(translation: [1, 0, 0]))
        }
        #expect(root.children.count == 1)
        #expect(root.children[0].transform == Transform(translation: [1, 0, 0]))
    }
}
