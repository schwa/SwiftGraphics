public extension SceneGraph {
    var currentCameraNode: Node? {
        get {
            guard let currentCameraPath else {
                return nil
            }
            return root[indexPath: currentCameraPath]
        }
        set {
            if let newValue {
                guard let currentCameraPath else {
                    fatalError("Trying to set current camera node, but no path for existing camera")
                }
                root[indexPath: currentCameraPath] = newValue
            }
            else {
                currentCameraPath = nil
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
