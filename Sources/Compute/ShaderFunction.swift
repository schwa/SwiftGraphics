import Metal

@dynamicMemberLookup
public struct ShaderLibrary: Sendable {
    public static let `default` = Self.bundle(.main)

    public static func bundle(_ bundle: Bundle, name: String? = nil) -> Self {
        Self { device in
            if let name {
                guard let url = bundle.url(forResource: name, withExtension: "metallib") else {
                    fatalError("Could not load metallib.")
                }
                let library = try device.makeLibrary(URL: url)
                library.label = "\(name).MTLLibrary"
                return library
            }
            else {
                let library = try device.makeDefaultLibrary(bundle: bundle)
                library.label = "Default.MTLLibrary"
                return library
            }
        }
    }

    public static func source(_ source: String) -> Self {
        Self { device in
            let options = MTLCompileOptions()
            options.enableLogging = true
            return try device.makeLibrary(source: source, options: options)
        }
    }

    var make: @Sendable (MTLDevice) throws -> MTLLibrary

    public func function(name: String) -> ShaderFunction {
        ShaderFunction(library: self, name: name)
    }

    public subscript(dynamicMember name: String) -> ShaderFunction {
        ShaderFunction(library: self, name: name)
    }

    internal func makelibrary(device: MTLDevice) throws -> MTLLibrary {
        try make(device)
    }
}

// MARK: -

public struct ShaderFunction: Identifiable {
    public let id = UUID()
    public let library: ShaderLibrary
    public let name: String
    public let constants: [ShaderConstant]

    public init(library: ShaderLibrary, name: String, constants: [ShaderConstant] = []) {
        self.library = library
        self.name = name
        self.constants = constants

        // MTLFunctionConstantValues
        // MTLDataType
    }
}

public struct ShaderConstant {
    var dataType: MTLDataType
    var accessor: ((UnsafeRawPointer) -> Void) -> Void

    public init(dataType: MTLDataType, value: [some Any]) {
        self.dataType = dataType
        accessor = { (callback: (UnsafeRawPointer) -> Void) in
            value.withUnsafeBytes { pointer in
                guard let baseAddress = pointer.baseAddress else {
                    fatalError("Could not get baseAddress.")
                }
                callback(baseAddress)
            }
        }
    }

    public init(dataType: MTLDataType, value: some Any) {
        self.dataType = dataType
        accessor = { (callback: (UnsafeRawPointer) -> Void) in
            withUnsafeBytes(of: value) { pointer in
                guard let baseAddress = pointer.baseAddress else {
                    fatalError("Could not get baseAddress.")
                }
                callback(baseAddress)
            }
        }
    }

    public func add(to values: MTLFunctionConstantValues, name: String) {
        accessor { pointer in
            values.setConstantValue(pointer, type: dataType, withName: name)
        }
    }
}
