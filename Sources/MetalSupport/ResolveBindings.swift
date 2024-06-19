import Metal

// TODO: These parameter names are terrible. But this is a very useful function.
// TODO: Want to validate types too if possible
public func resolveBindings<Bindable>(reflection: MTLRenderPipelineReflection, bindable: inout Bindable, _ a: [(WritableKeyPath<Bindable, Int?>, MTLFunctionType, String)]) {
    for (keyPath, shaderType, name) in a {
        bindable[keyPath: keyPath] = try! reflection.binding(for: name, of: shaderType)
    }
}

public extension MTLComputePipelineReflection {
    func binding(for name: String) throws -> Int {
        guard let binding = bindings.first(where: { $0.name == name }) else {
            throw MetalSupportError.missingBinding(name)
        }
        return binding.index
    }
}

public extension MTLRenderPipelineReflection {
    func binding(for name: String, of functionType: MTLFunctionType) throws -> Int {
        let bindings: [any MTLBinding]
        switch functionType {
        case .vertex:
            bindings = vertexBindings
        case .fragment:
            bindings = fragmentBindings
         case .object:
            bindings = objectBindings
        case .mesh:
            bindings = meshBindings
        default:
            fatalError("Unimplemented")
        }
        guard let binding = bindings.first(where: { $0.name == name }) else {
            throw MetalSupportError.missingBinding(name)
        }
        return binding.index
    }
}
