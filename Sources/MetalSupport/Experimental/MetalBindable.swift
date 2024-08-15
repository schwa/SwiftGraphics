import BaseSupport
import Metal

public protocol MetalBindable {
    static var bindingMappings: [(String, MTLFunctionType?, WritableKeyPath<Self, Int>)] { get }
}

public extension MetalBindable {
    mutating func updateBindings(with reflection: MTLComputePipelineReflection?) throws {
        guard let reflection else {
            fatalError("No reflection available.")
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
            throw BaseError.error(.resourceCreationFailure)
        }
        for (name, functionType, keyPath) in Self.bindingMappings {
            let bindingIndex: Int
            switch functionType {
            case .fragment:
                bindingIndex = try reflection.binding(for: name, of: .fragment)
            case .vertex:
                bindingIndex = try reflection.binding(for: name, of: .vertex)
            case .object:
                bindingIndex = try reflection.binding(for: name, of: .object)
            case .mesh:
                bindingIndex = try reflection.binding(for: name, of: .mesh)
            default:
                throw BaseError.error(.missingBinding(name))
            }
            self[keyPath: keyPath] = bindingIndex
        }
    }
}
