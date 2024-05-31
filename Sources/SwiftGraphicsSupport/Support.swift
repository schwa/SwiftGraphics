import CoreGraphicsSupport
import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders
import MetalSupportUnsafeConformances
import ModelIO
import os
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public enum RenderKitError: Error {
    case generic(String)
}

public protocol Labeled {
    var label: String? { get }
}
