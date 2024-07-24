import Metal

public enum ComputeError: Error {
    case resourceCreationFailure
    case missingBinding(String)
}

public struct Compute {
    public let device: MTLDevice
    let logState: MTLLogState?
    let commandQueue: MTLCommandQueue

    public init(device: MTLDevice, logState: MTLLogState? = nil) throws {
        self.device = device
        self.logState = logState
        let commandQueueDescriptor = MTLCommandQueueDescriptor()
        commandQueueDescriptor.logState = logState
        guard let commandQueue = device.makeCommandQueue(descriptor: commandQueueDescriptor) else {
            throw ComputeError.resourceCreationFailure
        }
        commandQueue.label = "Compute-MTLCommandQueue"
        self.commandQueue = commandQueue
    }

    public func task<R>(label: String? = nil, _ block: (Task) throws -> R) throws -> R {
        let commandBufferDescriptor = MTLCommandBufferDescriptor()
        commandBufferDescriptor.logState = logState

        guard let commandBuffer = commandQueue.makeCommandBuffer(descriptor: commandBufferDescriptor) else {
            throw ComputeError.resourceCreationFailure
        }
        commandBuffer.label = "\(label ?? "Unlabelled")-MTLCommandBuffer"
        defer {
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        let task = Task(label: label, commandBuffer: commandBuffer)
        return try block(task)
    }

    public func dispatch<R>(label: String? = nil, _ block: (Dispatcher) throws -> R) throws -> R {
        try task(label: label) { task in
            try task { dispatch in
                try block(dispatch)
            }
        }
    }

    public func makePass(function: ShaderFunction, constants: [String: Argument] = [:], arguments: [String: Argument] = [:]) throws -> Pass {
        try Pass(device: device, function: function, constants: constants, arguments: arguments)
    }
}

// MARK: -

public extension Compute {
    // TODO: Rename.
    struct Pass {
        public let function: ShaderFunction
        internal let bindings: [String: Int]
        public var arguments: Arguments
        public let computePipelineState: MTLComputePipelineState

        internal init(device: MTLDevice, function: ShaderFunction, constants: [String: Argument] = [:], arguments: [String: Argument] = [:]) throws {
            self.function = function

            let constantValues = MTLFunctionConstantValues()
            for (name, constant) in constants {
                constant.constantValue(constantValues, name)
            }

            let library = try function.library.makelibrary(device: device)

            let function = try library.makeFunction(name: function.name, constantValues: constantValues)
            function.label = "\(function.name)-MTLFunction"
            let computePipelineDescriptor = MTLComputePipelineDescriptor()
            computePipelineDescriptor.label = "\(function.name)-MTLComputePipelineState"
            //            computePipelineDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = false
            computePipelineDescriptor.computeFunction = function
            let (computePipelineState, reflection) = try device.makeComputePipelineState(descriptor: computePipelineDescriptor, options: [.bindingInfo])
            bindings = Dictionary(uniqueKeysWithValues: reflection!.bindings.map { binding in
                (binding.name, binding.index)
            })

            self.computePipelineState = computePipelineState
            self.arguments = Arguments(arguments: arguments)
        }

        public var maxTotalThreadsPerThreadgroup: Int {
            computePipelineState.maxTotalThreadsPerThreadgroup
        }

        public var threadExecutionWidth: Int {
            computePipelineState.threadExecutionWidth
        }

        func bind(_ commandEncoder: MTLComputeCommandEncoder) throws {
            for (name, value) in arguments.arguments {
                guard let index = bindings[name] else {
                    throw ComputeError.missingBinding(name)
                }
                value.encode(commandEncoder, index)
            }
        }
    }

    @dynamicMemberLookup
    struct Arguments {
        internal var arguments: [String: Argument]

        public subscript(dynamicMember name: String) -> Argument? {
            get {
                arguments[name]
            }
            set {
                arguments[name] = newValue
                // TODO: it would be nice to assign name as a label to buffers/textures that have no name.
            }
        }
    }

    struct Argument {
        // var bindingType: MTLBindingType

        internal var encode: (MTLComputeCommandEncoder, Int) -> Void
        internal var constantValue: (MTLFunctionConstantValues, String) -> Void

        public static func int(_ value: some BinaryInteger) -> Self {
            Self { encoder, index in
                withUnsafeBytes(of: value) { buffer in
                    encoder.setBytes(buffer.baseAddress!, length: buffer.count, index: index)
                }
            }
            constantValue: { constants, name in
                withUnsafeBytes(of: value) { buffer in
                    // TODO: may not be .int if T isn't Int32
                    constants.setConstantValue(buffer.baseAddress!, type: .int, withName: name)
                }
            }
        }

        public static func bool(_ value: Bool) -> Self {
            Self { encoder, index in
                withUnsafeBytes(of: value) { buffer in
                    encoder.setBytes(buffer.baseAddress!, length: buffer.count, index: index)
                }
            }
            constantValue: { constants, name in
                withUnsafeBytes(of: value) { buffer in
                    constants.setConstantValue(buffer.baseAddress!, type: .bool, withName: name)
                }
            }
        }

        public static func buffer(_ buffer: MTLBuffer, offset: Int = 0) -> Self {
            Self { encoder, index in
                encoder.setBuffer(buffer, offset: offset, index: index)
            }
            constantValue: { _, _ in
                fatalError("TODO: buffer")
            }
        }

        public static func texture(_ texture: MTLTexture) -> Self {
            Self { encoder, index in
                encoder.setTexture(texture, index: index)
            }
            constantValue: { _, _ in
                fatalError("TODO: texture")
            }
        }
    }

    struct Task {
        let label: String?
        let commandBuffer: MTLCommandBuffer

        public func callAsFunction<R>(_ block: (Dispatcher) throws -> R) throws -> R {
            try run(block)
        }

        public func run<R>(_ block: (Dispatcher) throws -> R) throws -> R {
            guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
                throw ComputeError.resourceCreationFailure
            }
            commandEncoder.label = "\(label ?? "Unlabelled")-MTLComputeCommandEncoder"

            defer {
                commandEncoder.endEncoding()
            }
            let dispatcher = Dispatcher(commandEncoder: commandEncoder)
            return try block(dispatcher)
        }
    }

    struct Dispatcher {
        let commandEncoder: MTLComputeCommandEncoder

        public func callAsFunction(pass: Pass, threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) throws {
            commandEncoder.setComputePipelineState(pass.computePipelineState)
            try pass.bind(commandEncoder)
            commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }

        public func callAsFunction(pass: Pass, threads: MTLSize, threadsPerThreadgroup: MTLSize) throws {
            commandEncoder.setComputePipelineState(pass.computePipelineState)
            try pass.bind(commandEncoder)
            commandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
        }
    }
}

extension Compute.Pass: CustomStringConvertible {
    public var description: String {
        "Compute.Pass(function: \(function), arguments: \(arguments)"
    }
}
