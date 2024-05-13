// import CoreGraphics
// import RenderKit
// import Metal
// import SwiftUI
//
// struct MetalGraphicsContext {
//    enum Command {
//        case stroke(Path)
//    }
//
//    var commands: [Command] = []
//
//    mutating func stroke(path: Path) {
//        commands.append(.stroke(path))
//    }
// }
//
// struct MetalGraphicsCanvas {
//    typealias Configuration = OffscreenRenderPassConfiguration
//
//    var size: CGSize
//
//    var renderPass: any RenderPass
//    var configuration: Configuration
//
//    init(size: CGSize) throws {
//        self.size = size
//        let device = MTLCreateSystemDefaultDevice()!
//        configuration = OffscreenRenderPassConfiguration(device: device, size: size)
//        configuration.colorPixelFormat = .bgra10_xr_srgb
//        configuration.update()
//        renderPass = AnyRenderPass { _, _ in
//            fatalError()
//        }
//        drawableSizeWillChange: { _, _, _ in
//            fatalError()
//        }
//        draw: { _, _, _, _, _ in
//            fatalError()
//        }
//    }
//
//    func draw<R>(_ block: (inout MetalGraphicsContext) throws -> R) rethrows -> R {
//        var context = MetalGraphicsContext()
//        let result = try block(&context)
//        try! render(context.commands) // TODO: try!
//        return result
//    }
//
//    func render(_ context: [MetalGraphicsContext.Command]) throws {
//        fatalError()
//    }
// }
