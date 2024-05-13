import Foundation
import CoreGraphics
import simd
import Everything
import SwiftUI
import MetalKit
import RenderKit
import RenderKitShaders
import Shapes2D
import CoreGraphicsSupport
import MetalSupport

// TODO: Move
extension CGVector {
    init(_ dx: CGFloat, _ dy: CGFloat) {
        self = CGVector(dx: dx, dy: dy)
    }
    init(_ size: CGSize) {
        self = CGVector(dx: size.width, dy: size.height)
    }
}

extension SIMD3 where Scalar == Float {
    var h: Float {
        get {
            return x
        }
        set {
            x = newValue
        }
    }

    var s: Float {
        get {
            return y
        }
        set {
            y = newValue
        }
    }

    var v: Float {
        get {
            return z
        }
        set {
            z = newValue
        }
    }

    func hsv2rgb() -> Self {
        let h_i = Int(h * 6)
        let f = h * 6 - Float(h_i)
        let p = v * (1 - s)
        let q = v * (1 - f * s)
        let t = v * (1 - (1 - f) * s)

        switch h_i {
        case 0: return [v, t, p]
        case 1: return [q, v, p]
        case 2: return [p, v, t]
        case 3: return [p, q, v]
        case 4: return [t, p, v]
        case 5: return [v, p, q]
        default: return [0, 0, 0]
        }
    }
}

extension Shapes2D.Circle {
    init(containing rect: CGRect) {
        let center = rect.midXMidY
        let diameter = sqrt(rect.width ** 2 + rect.height ** 3)
        self = .init(center: center, diameter: diameter)
    }
}

extension Triangle {
    init(containing circle: Shapes2D.Circle) {
        let a = circle.center + CGPoint(distance: circle.radius * 2, angle: Angle.degrees(0))
        let b = circle.center + CGPoint(distance: circle.radius * 2, angle: Angle.degrees(120))
        let c = circle.center + CGPoint(distance: circle.radius * 2, angle: Angle.degrees(240))
        self = .init(a, b, c)
    }
}

class Once {
    // TODO: The thread safety, it's missing!!!!
    var tokens: Set<AnyHashable> = []
    static let shared = Once()
}

func once(_ token: AnyHashable, block: () throws -> Void) rethrows {
    guard Once.shared.tokens.insert(token).inserted else {
        return
    }
    try block()
}

extension MTLOrigin: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Int...) {
        self = .init(x: elements[0], y: elements[1], z: elements[2])
    }
}

extension MTLDepthStencilDescriptor {
    static func always() -> MTLDepthStencilDescriptor {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .always
        descriptor.label = "always"
        return descriptor
    }
}

extension MTLRenderPipelineColorAttachmentDescriptor {
    func enableStandardAlphaBlending() {
        isBlendingEnabled = true
        rgbBlendOperation = .add
        alphaBlendOperation = .add
        sourceRGBBlendFactor = .sourceAlpha
        sourceAlphaBlendFactor = .sourceAlpha
        destinationRGBBlendFactor = .oneMinusSourceAlpha
        destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
}

extension MTLBuffer {
    func contentsBuffer() -> UnsafeMutableRawBufferPointer {
        UnsafeMutableRawBufferPointer(start: contents(), count: length)
    }

    func contentsBuffer <T>(of type: T.Type) -> UnsafeMutableBufferPointer <T> {
        contentsBuffer().bindMemory(to: type)
    }
}

extension MTLBuffer {
    func labelled(_ label: String) -> MTLBuffer {
        self.label = label
        return self
    }
}

struct ShowOnHoverModifier: ViewModifier {
    @State
    var hovering = false

    func body(content: Content) -> some View {
        ZStack {
            Color.clear
            content.opacity(hovering ? 1 : 0)
        }
        .onHover { hovering in
            self.hovering = hovering
        }
    }
}

extension View {
    func showOnHover() -> some View {
        modifier(ShowOnHoverModifier())
    }
}

extension YAMesh {
    static func simpleMesh(label: String? = nil, primitiveType: MTLPrimitiveType = .triangle, device: MTLDevice, content: () -> ([UInt16], [SimpleVertex])) throws -> YAMesh {
        let (indices, vertices) = content()
        return try simpleMesh(label: label, indices: indices, vertices: vertices, primitiveType: primitiveType, device: device)
    }
}

private class PrintOnceManager {
    static let instance = PrintOnceManager()

    var printedAlready: Set<String> = []

    func printedAlready(_ s: String) -> Bool {
        if printedAlready.contains(s) {
            return true
        }
        printedAlready.insert(s)
        return false
    }
}

func printOnce(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    var s = ""
    print(items, separator: separator, terminator: terminator, to: &s)
    guard PrintOnceManager.instance.printedAlready(s) == false else {
        return
    }
    print(s, terminator: "")
}

struct Pair <LHS, RHS> {
    var lhs: LHS
    var rhs: RHS

    init(_ lhs: LHS, _ rhs: RHS) {
        self.lhs = lhs
        self.rhs = rhs
    }

    init(_ value: (LHS, RHS)) {
        self.lhs = value.0
        self.rhs = value.1
    }
}

extension Pair: Equatable where LHS: Equatable, RHS: Equatable {
}

extension Pair: Hashable where LHS: Hashable, RHS: Hashable {
}
