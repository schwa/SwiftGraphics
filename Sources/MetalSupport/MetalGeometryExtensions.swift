import Metal

public extension MTLOrigin {
    init(_ origin: CGPoint) {
        self.init(x: Int(origin.x), y: Int(origin.y), z: 0)
    }

    static var zero: MTLOrigin {
        MTLOrigin(x: 0, y: 0, z: 0)
    }
}

public extension MTLRegion {
    init(_ rect: CGRect) {
        self = MTLRegion(origin: MTLOrigin(rect.origin), size: MTLSize(rect.size))
    }
}

public extension MTLSize {
    init(_ size: CGSize) {
        self.init(width: Int(size.width), height: Int(size.height), depth: 1)
    }

    init(_ width: Int, _ height: Int, _ depth: Int) {
        self = MTLSize(width: width, height: height, depth: depth)
    }

    init(width: Int) {
        self = MTLSize(width: width, height: 1, depth: 1)
    }
}

public extension SIMD4<Double> {
    init(_ clearColor: MTLClearColor) {
        self = [clearColor.red, clearColor.green, clearColor.blue, clearColor.alpha]
    }
}
