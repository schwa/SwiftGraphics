import CoreGraphics
import Metal
import MetalUISupport

@available(*, deprecated, message: "Deprecated")
public protocol RenderPass: AnyObject {
    func setup<Configuration: MetalConfiguration>(device: MTLDevice, configuration: inout Configuration) throws
    func drawableSizeWillChange(device: MTLDevice, size: CGSize) throws
    func draw(device: MTLDevice, size: CGSize, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws
}

@available(*, deprecated, message: "Deprecated")
public extension RenderPass {
    func drawableSizeWillChange(device: MTLDevice, size: CGSize) throws {
    }
}

// MARK: -

// TODO: Combine jobs and passes

@available(*, deprecated, message: "Deprecated")
public protocol RenderJob: AnyObject {
    func setup<Configuration: MetalConfiguration>(device: MTLDevice, configuration: inout Configuration) throws
    func drawableSizeWillChange(device: MTLDevice, size: CGSize) throws
    func encode(on encoder: MTLRenderCommandEncoder, size: CGSize) throws // TODO: Add configuration just to be consistent? Or remove from renderpass.
}

@available(*, deprecated, message: "Deprecated")
public extension RenderJob {
    func drawableSizeWillChange(device: MTLDevice, size: CGSize) throws {
    }
}
