import ModelIO

extension MDLMeshBufferType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .index:
            "index"
        case .vertex:
            "vertex"
        default:
            fatalError(MetalSupportError.illegalValue)
        }
    }
}

extension MDLGeometryType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .lines:
            return "lines"
        case .points:
            return "points"
        case .triangles:
            return "triangles"
        case .triangleStrips:
            return "triangleStrips"
        case .quads:
            return "quads"
        case .variableTopology:
            return "variableTopology"
        @unknown default:
            return "unknown"
        }
    }
}
