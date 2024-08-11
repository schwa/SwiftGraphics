public extension SceneGraph {
    var currentCameraNode: Node? {
        get {
            guard let currentCameraAccessor else {
                return nil
            }
            return root[accessor: currentCameraAccessor]
        }
        set {
            if let newValue {
                guard let currentCameraAccessor else {
                    fatalError("Trying to set current camera node, but no accessor for existing camera.")
                }
                root[accessor: currentCameraAccessor] = newValue
            } else {
                currentCameraAccessor = nil
            }
        }
    }

    var currentCamera: Camera? {
        get {
            currentCameraNode?.camera
        }
        set {
            currentCameraNode?.camera = newValue
        }
    }
}

public extension SceneGraph {
    var unsafeCurrentCameraNode: Node {
        get {
            currentCameraNode.forceUnwrap("No current camera node")
        }
        set {
            currentCameraNode = newValue
        }
    }
}
