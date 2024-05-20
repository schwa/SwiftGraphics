import MetalKit
import MetalSupport
import ModelIO
import SIMDSupport
import SwiftUI

public struct Cylinder3D {
    public var radius: Float
    public var depth: Float

    public init(radius: Float, depth: Float) {
        self.radius = radius
        self.depth = depth
    }
}
