// periphery:ignore:all

#if os(iOS) && !targetEnvironment(simulator)
import ARKit
import BaseSupport
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
            fatalError(BaseError.illegalValue)
        }
    }
}
#endif
