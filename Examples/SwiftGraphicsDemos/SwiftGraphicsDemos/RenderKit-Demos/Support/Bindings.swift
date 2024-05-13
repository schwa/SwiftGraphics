import Metal

// TODO: These parameter names are terrible. But this is a very useful function.
// TODO: Want to validate types too if possible
func resolveBindings<Bindable>(reflection: MTLRenderPipelineReflection, bindable: inout Bindable, _ a: [(WritableKeyPath<Bindable, Int>, MTLFunctionType, String)]) {
    for (keyPath, shaderType, name) in a {
        switch shaderType {
        case .vertex:
            let binding = reflection.vertexBindings.first(where: { $0.name == name })!
            bindable[keyPath: keyPath] = binding.index
        case .fragment:
            let binding = reflection.fragmentBindings.first(where: { $0.name == name })!
            bindable[keyPath: keyPath] = binding.index
        default:
            fatalError()
        }
    }
}
