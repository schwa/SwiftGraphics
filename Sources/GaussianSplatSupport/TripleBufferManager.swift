@preconcurrency import Metal
import os

class TripleBufferManager <T>: @unchecked Sendable where T: Sendable {
    var sharedEvent: MTLSharedEvent
    var sharedEventListener: MTLSharedEventListener

    enum State {
        case free
        case inUseByCPU
        case ready
        case inUseByGPU
    }

    struct ManagedValue: Identifiable {
        var id: Int
        var state: State
        var value: T
    }

    var managedValues: OSAllocatedUnfairLock<[ManagedValue]>

    var count: Int {
        managedValues.withLock { managedValues in
            managedValues.count
        }
    }

    init(device: MTLDevice, values: [T]) {
        self.managedValues = .init(initialState: values.enumerated().map { .init(id: $0.0, state: .free, value: $0.1) })
        let myQueue = DispatchQueue(label: "com.example.apple-samplecode.MyQueue")
        sharedEventListener = MTLSharedEventListener(dispatchQueue: myQueue)
        sharedEvent = device.makeSharedEvent()!
    }

    func requestCPUValue() -> ManagedValue {
        let value = managedValues.withLock { managedValues -> ManagedValue? in
            guard let index = managedValues.lastIndex(where: { $0.state == .free }) ?? managedValues.lastIndex(where: {
                $0.state == .ready }) else {
                return nil
            }
            managedValues[index].state = .inUseByCPU
            return managedValues[index]
        }
        guard let value else {
            fatalError()
        }
        return value
    }

    func finishedWithCPUValue(_ value: ManagedValue) {
        fatalError()
    }

    func gpuWork() -> GPUWork<T> {
        fatalError()
    }
}

extension TripleBufferManager: CustomDebugStringConvertible {
    var debugDescription: String {
        "TripleBufferManager()"
    }
}

public struct GPUWork<T>: Sendable, Equatable where T: Sendable {
    public var id = UUID()
    public var element: T
    public var sharedEvent: MTLSharedEvent
    public var encode: @Sendable () -> Void

    public func encodeSignal(on commandBuffer: MTLCommandBuffer) {
//        print("XYZZY: Encoding signal \(sharedEvent.signaledValue + 1).")
        encode()
        commandBuffer.encodeSignalEvent(sharedEvent, value: sharedEvent.signaledValue + 1)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
