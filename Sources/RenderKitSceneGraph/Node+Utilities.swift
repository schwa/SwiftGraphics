import Foundation
import simd
import SIMDSupport
import SwiftUI

public extension Node {
    func dump() -> String {
        var s = ""
        for (node, accessor) in allAccessors() {
            let indent = String(repeating: "  ", count: accessor.path.count)
            s += "\(indent)Node(id: \"\(node.id)\", transform: \(node.transform), accessor: #\(accessor))\n"
            if let content = node.content {
                s += "\(indent)  content: \(content))\n"
            }
        }
        return s
    }
}

public extension Node {
    func transformed(_ transform: Transform) -> Node {
        var copy = self
        if copy.transform == .identity {
            copy.transform = transform
        }
        else {
            copy.transform.matrix = transform.matrix * copy.transform.matrix
        }
        return copy
    }
    func transformed(scale: SIMD3<Float>) -> Node {
        transformed(Transform(scale: scale))
    }
    func transformed(rotation: Rotation) -> Node {
        transformed(Transform(rotation: rotation))
    }
    func transformed(roll: Angle, pitch: Angle, yaw: Angle) -> Node {
        transformed(Transform(roll: roll, pitch: pitch, yaw: yaw))
    }
    func transformed(translation: SIMD3<Float>) -> Node {
        transformed(.translation(translation))
    }
    @available(*, deprecated, message: "Deprecated")
    func withContent(_ content: Content) -> Node {
        var copy = self
        copy.content = content
        return copy
    }
    @available(*, deprecated, message: "Deprecated")
    func withChildren(@NodeBuilder _  children: () -> [Node]) -> Node {
        var copy = self
        copy.children = children()
        return copy
    }
}
