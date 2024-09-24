@preconcurrency import Metal

class TripleBufferManager <T> where T: Sendable {
    var sharedEvent: MTLSharedEvent
    var sharedEventListener: MTLSharedEventListener

    var freeElements: [T] {
        didSet {
            releaseAssert(freeElements.count <= 3)
        }
    }
    var cpuProcessedElements: [T] = [] {
        didSet {
            releaseAssert(cpuProcessedElements.count <= 1)
        }
    }
    var gpuInFlightElements: [T] = [] {
        didSet {
            releaseAssert(gpuInFlightElements.count <= 1)
        }
    }

    init(device: MTLDevice, initialValue: T) {
        let myQueue = DispatchQueue(label: "com.example.apple-samplecode.MyQueue")
        sharedEventListener = MTLSharedEventListener(dispatchQueue: myQueue)
        freeElements = Array(repeating: initialValue, count: 3)
        sharedEvent = device.makeSharedEvent()!

        sharedEvent.notify(sharedEventListener, atValue: 0) { _, _ in
            self.freeElements.append(contentsOf: self.gpuInFlightElements)
            self.gpuInFlightElements.removeAll()
        }
    }

    func requestCPUElement() -> T {
        guard var element = freeElements.popLast() else {
            fatalError("No free elements.")
        }
        return element
    }

    func finishedWithCPUElement(_ element: T) {
        freeElements.append(contentsOf: cpuProcessedElements)
        cpuProcessedElements.removeAll()
        cpuProcessedElements.append(element)
    }

//    func cpuWork<R>(_ work: @Sendable (inout T) throws -> R) rethrows -> R {
//        guard var element = freeElements.popLast() else {
//            fatalError("No free elements.")
//        }
//        defer {
//            freeElements.append(contentsOf: cpuProcessedElements)
//            cpuProcessedElements.removeAll()
//            cpuProcessedElements.append(element)
//        }
//        return try work(&element)
//    }

    func gpuWork() -> GPUWork<T> {
        guard let element = cpuProcessedElements.popLast() else {
            fatalError("No elements ready for GPU")
        }
        gpuInFlightElements.append(element)
        return .init(element: element, sharedEvent: sharedEvent)
    }
}

public struct GPUWork<T>: Sendable, Equatable where T: Sendable {
    public var id = UUID()
    public var element: T
    public var sharedEvent: MTLSharedEvent

    public func encodeSignal(on commandBuffer: MTLCommandBuffer) {
        commandBuffer.encodeSignalEvent(sharedEvent, value: sharedEvent.signaledValue + 1)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Treat an Optional as a single element queue…
extension Optional {
    mutating func append(_ wrapped: Wrapped) {
        self = .init(wrapped)
    }

    mutating func popLast() -> Wrapped? {
        // swiftlint:disable:next self_binding
        if let wrapped = self {
            self = nil
            return wrapped
        }
        else {
            return nil
        }
    }
}
