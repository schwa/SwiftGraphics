public protocol LightProtocol: Sendable {
}

public extension Node {
    var light: (any LightProtocol)? {
        get {
            content as? (any LightProtocol)
        }
        set {
            content = newValue
        }
    }
}
