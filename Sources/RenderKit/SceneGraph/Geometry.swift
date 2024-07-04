import BaseSupport
import Foundation
@preconcurrency import MetalKit
import os
import SIMDSupport

public protocol MaterialProtocol: Sendable, Equatable {
}

public struct Geometry: Sendable, Equatable {
    public var mesh: MTKMesh
    public var materials: [any MaterialProtocol]

    public init(mesh: MTKMesh, materials: [any MaterialProtocol]) {
        self.mesh = mesh
        self.materials = materials
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.mesh == rhs.mesh else {
            return false
        }
        let lhs = lhs.materials.map { AnyEquatable($0) }
        let rhs = rhs.materials.map { AnyEquatable($0) }
        return lhs == rhs
    }
}

extension Geometry: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Geometry(mesh: \(mesh), materials: \(materials))"
    }
}

public extension Node {
    var geometry: Geometry? {
        get {
            content as? Geometry
        }
        set {
            content = newValue
        }
    }
}
