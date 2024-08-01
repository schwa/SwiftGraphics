import BaseSupport
import Metal

public extension MTLComputePipelineReflection {
    func binding(for name: String) throws -> Int {
        guard let binding = bindings.first(where: { $0.name == name }) else {
            let bindings = bindings.map(\.name)
            logger?.debug("Failed to find binding for \(name). Valid binding names are: \(bindings.joined(separator: ", "))")
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
            unimplemented()
        }
        guard let binding = bindings.first(where: { $0.name == name }) else {
            throw BaseError.invalidParameter
        }
        return binding.index
    }
}
