import CoreGraphicsSupport
import Everything
import Foundation
import MetalKit
import MetalSupport
import Observation
import RenderKit
import simd
import SIMDSupport
import SwiftFormats
import SwiftGraphicsSupport
import SwiftUI
import UniformTypeIdentifiers

@Observable
public class GaussianSplatViewModel {
//    public var splats: Splats<SplatC>
//    public var cameraTransform: Transform = .translation([0, 0, 3])
//    public var cameraProjection: Projection = .perspective(.init())
//    public var modelTransform = Transform.identity.rotated(angle: .degrees(180), axis: [1, 0, 0])
    public var debugMode: Bool
    public var sortRate: Int

    public init(debugMode: Bool = false, sortRate: Int = 1) {
        self.debugMode = debugMode
        self.sortRate = sortRate
    }
}
