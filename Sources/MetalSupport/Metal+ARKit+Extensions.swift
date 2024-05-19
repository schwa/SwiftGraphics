#if os(iOS) && !targetEnvironment(simulator)
import ARKit
import Metal

public extension MTLPrimitiveType {
    init(_ type: ARGeometryPrimitiveType) {
        switch type {
        case .line:
            self = .line
        case .triangle:
            self = .triangle
        @unknown
        default:
            fatalError(MetalSupportError.illegalValue)
        }
    }
}
#endif
