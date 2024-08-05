import Foundation
import simd
import SIMDSupport
import SwiftUI

public extension Node {
    func dump() -> String {
        var s = ""
        for (node, accessor) in allAccessors() {
            let indent = String(repeating: "  ", count: accessor.path.count)
            print("\(indent)Node(id: \"\(node.id)\", transform: \(node.transform), accessor: #\(accessor))", to: &s)
            if let content = node.content {
                print("\(indent)  content: \(content))", to: &s)
            }
        }
        return s
    }
}

public extension Node {
    func transform(_ transform: Transform) -> Node {
        var copy = self
        if copy.transform == .identity {
            copy.transform = transform
        }
        else {
            copy.transform.matrix = transform.matrix * copy.transform.matrix
        }
        return copy
    }
    func transform(scale: SIMD3<Float>) -> Node {
        transform(Transform(scale: scale))
    }
    func transform(rotation: Rotation) -> Node {
        transform(Transform(rotation: rotation))
    }
    func transform(roll: Angle, pitch: Angle, yaw: Angle) -> Node {
        transform(Transform(roll: roll, pitch: pitch, yaw: yaw))
    }
    func transform(translation: SIMD3<Float>) -> Node {
        transform(.translation(translation))
    }
    func content(_ content: Content) -> Node {
        var copy = self
        copy.content = content
        return copy
    }
    func children(@NodeBuilder _  children: () -> [Node]) -> Node {
        var copy = self
        copy.children = children()
        return copy
    }
}
