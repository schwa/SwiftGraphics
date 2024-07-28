import BaseSupport
import Foundation
import Testing
@testable import RenderKitSceneGraph

struct NodeAccessorTests {
    @Test
    func testNodeAccessorWithLabels() {
        let rootNode = Node(label: "Root", children: [
            Node(label: "Child1"),
            Node(label: "Child2", children: [
                Node(label: "Grandchild")
            ])
        ])

        let child1 = rootNode.firstNode(label: "Child1")
        #expect(child1?.label == "Child1")

        let child2 = rootNode.firstNode(label: "Child2")
        #expect(child2?.label == "Child2")

        let grandchild = rootNode.firstNode(label: "Grandchild")
        #expect(grandchild?.label == "Grandchild")

        let nonexistent = rootNode.firstNode(label: "Nonexistent")
        #expect(nonexistent == nil)
    }

    @Test
    func testAllNodesIteration() {
        let rootNode = Node(label: "Root", children: [
            Node(label: "Child1"),
            Node(label: "Child2", children: [
                Node(label: "Grandchild")
            ])
        ])

        let allNodes = Array(rootNode.allNodes())
        #expect(allNodes.count == 4)
        #expect(allNodes.map(\.label) == ["Root", "Child1", "Child2", "Grandchild"])
    }

    @Test
    func testFirstAccessorMatching() {
        let rootNode = Node(label: "Root", children: [
            Node(label: "Child1"),
            Node(label: "Child2", children: [
                Node(label: "Grandchild")
            ])
        ])

        let accessorChild1 = rootNode.firstAccessor(label: "Child1")
        #expect(accessorChild1 != nil)

        let accessorGrandchild = rootNode.firstAccessor(label: "Grandchild")
        #expect(accessorGrandchild != nil)

        let accessorNonexistent = rootNode.firstAccessor(label: "Nonexistent")
        #expect(accessorNonexistent == nil)
    }

    @Test
    func testSceneGraphAccessorOperations() {
        var sceneGraph = SceneGraph(root: Node(label: "Root", children: [
            Node(label: "Child1"),
            Node(label: "Child2", children: [
                Node(label: "Grandchild")
            ])
        ]))

        // Test accessing nodes
        let child1 = sceneGraph.firstNode(label: "Child1")
        #expect(child1?.label == "Child1")

        let grandchild = sceneGraph.firstNode(label: "Grandchild")
        #expect(grandchild?.label == "Grandchild")

        // Test modifying nodes
        do {
            try sceneGraph.modify(label: "Child1") { node in
                node?.label = "Modified Child1"
            }
            let modifiedChild1 = sceneGraph.firstNode(label: "Modified Child1")
            #expect(modifiedChild1?.label == "Modified Child1")
        } catch {
            Issue.record("Failed to modify node: \(error)")
        }

        // Test modifying non-existent node
        do {
            try sceneGraph.modify(label: "Nonexistent") { _ in }
            Issue.record("Should have thrown an error")
        } catch {
            // Expected to catch an error
        }
    }

    @Test
    func testSceneGraphModification() {
        var sceneGraph = SceneGraph(root: Node(label: "Root"))

        // Add a child node
        do {
            try sceneGraph.modify(label: "Root") { node in
                node?.children.append(Node(label: "NewChild"))
            }
            let newChild = sceneGraph.firstNode(label: "NewChild")
            #expect(newChild != nil)
        } catch {
            Issue.record("Failed to add new child node: \(error)")
        }

        // Modify the newly added child
        do {
            try sceneGraph.modify(label: "NewChild") { node in
                node?.label = "ModifiedNewChild"
            }
            let modifiedChild = sceneGraph.firstNode(label: "ModifiedNewChild")
            #expect(modifiedChild != nil)
        } catch {
            Issue.record("Failed to modify new child node: \(error)")
        }

        // Attempt to modify a non-existent node
        do {
            try sceneGraph.modify(label: "NonexistentNode") { _ in }
            Issue.record("Should have thrown an error for non-existent node")
        } catch {
            // Expected to catch an error
        }
    }
}
