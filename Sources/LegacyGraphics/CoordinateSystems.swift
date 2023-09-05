import CoreGraphics

public enum GraphicsOrigin {
    case topLeft
    case bottomLeft
    case native

    var resolved: GraphicsOrigin {
        switch self {
        case .topLeft, .bottomLeft:
            return self
        case .native:
            #if os(OSX)
                return .topLeft
            #else
                return .bottomLeft
            #endif
        }
    }

    var isNative: Bool {
        switch self {
        case .topLeft:
            #if os(OSX)
                return false
            #else
                return true
            #endif
        case .bottomLeft:
            #if os(OSX)
                return true
            #else
                return false
            #endif
        case .native:
            return true
        }
    }
}
