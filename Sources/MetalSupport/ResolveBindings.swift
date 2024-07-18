import BaseSupport
import Metal

public extension MTLComputePipelineReflection {
    func binding(for name: String) throws -> Int {
        guard let binding = bindings.first(where: { $0.name == name }) else {
            throw BaseError.missingValue
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
            throw BaseError.generic("Could not bind '\(name)' to \(functionType) function.")
        }
        return binding.index
    }
}
