import BaseSupport
import Metal

public protocol MetalBindable {
    static var bindingMappings: [(String, MTLFunctionType?, WritableKeyPath<Self, Int>)] { get }
}

public extension MetalBindable {
    mutating func updateBindings(with reflection: MTLComputePipelineReflection?) throws {
        guard let reflection else {
            fatalError()
        }
        for (name, functionType, keyPath) in Self.bindingMappings {
            switch functionType {
            case .kernel, nil:
                let bindingIndex = try reflection.binding(for: name)
                self[keyPath: keyPath] = bindingIndex
            default:
                fatalError("Unsupported function type.")
            }
        }
    }

    mutating func updateBindings(with reflection: MTLRenderPipelineReflection?) throws {
        guard let reflection else {
            throw BaseError.resourceCreationFailure
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
                throw BaseError.invalidParameter
            }
        }
    }
}
