import BaseSupport
import CoreGraphics
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

extension CGImage {
    func convert(bitmapInfo: CGBitmapInfo) -> CGImage? {
        let width = width
        let height = height
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}

func convertCGImageEndianness2(_ inputImage: CGImage) -> CGImage? {
    let width = inputImage.width
    let height = inputImage.height
    let bitsPerComponent = 8
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // Choose the appropriate bitmap info for the target endianness
    let bitmapInfo: CGBitmapInfo
    if inputImage.byteOrderInfo == .order32Little {
        bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
    } else {
        bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    }

    guard let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: bitsPerComponent,
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
        return nil
    }

    // Draw the original image into the new context
    context.draw(inputImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    // Create a new CGImage from the context
    return context.makeImage()
}
