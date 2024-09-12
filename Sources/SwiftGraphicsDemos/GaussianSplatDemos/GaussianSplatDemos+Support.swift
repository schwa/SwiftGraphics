import BaseSupport
import Foundation
import GaussianSplatSupport
import Metal
import RenderKit
import RenderKitSceneGraph
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

// MARK: -

extension Int {
    var toDouble: Double {
        get {
            Double(self)
        }
        set {
            self = Int(newValue)
        }
    }
}

extension SceneGraph {
    // TODO: Rename - `unsafeSplatsNode`
    var splatsNode: Node {
        get {
            let accessor = self.firstAccessor(label: "splats")!
            return self[accessor: accessor]!
        }
        set {
            let accessor = self.firstAccessor(label: "splats")!
            self[accessor: accessor] = newValue
        }
    }
}

extension UTType {
    static let splat = UTType(filenameExtension: "splat")!
}
