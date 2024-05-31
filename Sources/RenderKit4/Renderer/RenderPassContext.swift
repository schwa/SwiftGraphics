import Foundation
import Metal
import os
import SwiftGraphicsSupport

public protocol RenderPassContextProtocol {
    var renderContext: RenderContext { get }
    var colorPixelFormat: MTLPixelFormat { get }
    var depthAttachmentPixelFormat: MTLPixelFormat { get }
}

// MARK: -

/// Passed to RenderPass. This struct captures important state and information about the render view that render passes may need.
public struct RenderPassContext: RenderPassContextProtocol {
    public var renderContext: RenderContext
    public var colorPixelFormat: MTLPixelFormat
    public var depthAttachmentPixelFormat: MTLPixelFormat
}

public extension RenderPassContextProtocol {
    var device: MTLDevice {
        renderContext.device
    }

    var library: MTLLibrary {
        renderContext.library
    }

    var logger: Logger? {
        renderContext.logger
    }
}
