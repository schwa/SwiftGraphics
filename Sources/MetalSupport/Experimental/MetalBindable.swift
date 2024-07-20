import Metal

public protocol MetalBindable {
    static var bindingMappings: [(String, MTLFunctionType?, WritableKeyPath<Self, Int>)] { get }
}

public extension MetalBindable {
    mutating func updateBindings(with reflection: MTLRenderPipelineReflection?) throws {
        guard let reflection else {
            fatalError()
        }
        for (name, functionType, keyPath) in Self.bindingMappings {
            switch functionType {
            case .fragment:
                let bindingIndex = try reflection.binding(for: name, of: .fragment)
                self[keyPath: keyPath] = bindingIndex
            case .vertex:
                let bindingIndex = try reflection.binding(for: name, of: .vertex)
                self[keyPath: keyPath] = bindingIndex
            default:
                fatalError()
            }
        }
    }
}
