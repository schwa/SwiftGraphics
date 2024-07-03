import SwiftGraphicsSupport

public extension Node {
    var camera: Camera? {
        get {
            content as? Camera
        }
        set {
            content = newValue
        }
    }
}
