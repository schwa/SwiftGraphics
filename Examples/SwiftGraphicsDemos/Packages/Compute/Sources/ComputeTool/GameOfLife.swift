import AVFoundation
import Compute
import Foundation
import Metal

struct GameOfLife {
    let width = 16
    let height = 16
    let device = MTLCreateSystemDefaultDevice()!

    func main() throws {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Uint, width: width, height: height, mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        let textureA = device.makeTexture(descriptor: textureDescriptor)!
        textureA.label = "texture-a"
        let textureB = device.makeTexture(descriptor: textureDescriptor)!
        textureB.label = "texture-b"
        let compute = try Compute(device: device)
        let library = ShaderLibrary.bundle(.module)
        var randomFillPass = try compute.makePass(function: library.randomFill_uint)
        randomFillPass.arguments.outputTexture = .texture(textureA)

        var gameOfLifePassA = try compute.makePass(function: library.gameOfLife_uint, constants: ["wrap": .bool(false)])
        gameOfLifePassA.arguments.inputTexture = .texture(textureA)
        gameOfLifePassA.arguments.outputTexture = .texture(textureB)
//        print(gameOfLifePassA)

        var gameOfLifePassB = gameOfLifePassA
        gameOfLifePassB.arguments.inputTexture = .texture(textureB)
        gameOfLifePassB.arguments.outputTexture = .texture(textureA)

        let assetWriter = try AVAssetWriter(outputURL: URL(filePath: "1234.mp4"), fileType: .mp4)

        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
        ])
        assetWriterVideoInput.expectsMediaDataInRealTime = false
        assetWriter.add(assetWriterVideoInput)

        let assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferMetalCompatibilityKey as String: true,
        ])

        assetWriter.startWriting()

        print(assetWriterPixelBufferInput)
//        guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
//            fatalError()
//        }
//                print(pixelBufferPool)

        try compute.task { task in
            try task { dispatch in
                try dispatch(pass: randomFillPass, threadgroupsPerGrid: MTLSize(width: width, height: height, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
            }
        }

        for _ in 0 ..< 10 {
            try compute.task { task in
                try task { dispatch in
                    try dispatch(pass: gameOfLifePassA, threadgroupsPerGrid: MTLSize(width: width, height: height, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
                }
            }

            try compute.task { task in
                try task { dispatch in
                    try dispatch(pass: gameOfLifePassA, threadgroupsPerGrid: MTLSize(width: width, height: height, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
                }
            }
        }

        print(textureA.toString())
        print(textureB.toString())
    }
}
