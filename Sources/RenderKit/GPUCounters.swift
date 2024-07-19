import Everything
import Metal
import Observation
import SwiftUI

// TODO: FIXME - unchecked Sendable
@Observable
public class GPUCounters: @unchecked Sendable {
    @ObservationIgnored
    var device: MTLDevice

    @ObservationIgnored
    var counterSampleBuffer: MTLCounterSampleBuffer?

    @ObservationIgnored
    var maxSamples = 60

    @ObservationIgnored
    var lastSampleTimestamp: UInt64?

    public struct Measurement: Sendable {
        public enum Kind: String, Hashable, Sendable {
            case frame
            case computeShader
            case vertexShader
            case fragmentShader
        }

        public struct Sample: Sendable {
            public var timestamp: UInt64
            public var value: UInt64

            public init(timestamp: UInt64, value: UInt64) {
                self.timestamp = timestamp
                self.value = value
            }
        }

        public var id: Kind
        public var maxSamples: Int
        public var samples: [Sample] = []
        public var movingAverage = ExponentialMovingAverageIrregular()

        public init(id: Kind, maxSamples: Int, samples: [Sample] = []) {
            self.id = id
            self.maxSamples = maxSamples
            self.samples = samples
            self.movingAverage = ExponentialMovingAverageIrregular()
            for sample in samples {
                self.movingAverage.update(time: Double(sample.timestamp), value: Double(sample.value))
            }
        }

        mutating func addSample(timestamp: UInt64, value: UInt64) {
            let sample = Sample(timestamp: timestamp, value: value)
            samples.append(sample)
            samples = Array(samples.suffix(maxSamples))
            movingAverage.update(time: Double(timestamp), value: Double(value))
        }
    }

    @ObservationIgnored
    public private(set) var measurements: [Measurement.Kind: Measurement] = [:]

    public init(device: MTLDevice) throws {
        //        print("atStageBoundary", device.supportsCounterSampling(.atStageBoundary))
        //        print("atDrawBoundary", device.supportsCounterSampling(.atDrawBoundary))
        //        print("atDispatchBoundary", device.supportsCounterSampling(.atDispatchBoundary))
        //        print("atTileDispatchBoundary", device.supportsCounterSampling(.atTileDispatchBoundary))
        //        print("atBlitBoundary", device.supportsCounterSampling(.atBlitBoundary))
        //        print(MTLCommonCounterSet.timestamp)
        //        print(MTLCommonCounterSet.stageUtilization)
        //        print(MTLCommonCounterSet.statistic)

        self.device = device
        if let counterSets = device.counterSets {
            guard let counterSet = counterSets.first(where: { $0.name == MTLCommonCounterSet.timestamp.rawValue }) else {
                fatalError("Could not find timestamp counter set")
            }
            let counterSampleBufferDescriptor = MTLCounterSampleBufferDescriptor()
            counterSampleBufferDescriptor.sampleCount = 4
            counterSampleBufferDescriptor.storageMode = .shared
            counterSampleBufferDescriptor.label = "My counter sample buffer"
            counterSampleBufferDescriptor.counterSet = counterSet
            counterSampleBuffer = try device.makeCounterSampleBuffer(descriptor: counterSampleBufferDescriptor)
        }
    }

    public func updateBuffer(renderPassDescriptor: MTLRenderPassDescriptor) {
        if let counterSampleBuffer {
            renderPassDescriptor.sampleBufferAttachments[0].startOfVertexSampleIndex = 0
            renderPassDescriptor.sampleBufferAttachments[0].endOfVertexSampleIndex = 1
            renderPassDescriptor.sampleBufferAttachments[0].startOfFragmentSampleIndex = 2
            renderPassDescriptor.sampleBufferAttachments[0].endOfFragmentSampleIndex = 3
            renderPassDescriptor.sampleBufferAttachments[0].sampleBuffer = counterSampleBuffer
        }
    }

    public func gatherData() throws {
        let timestamp = getMachTimeInNanoseconds()
        if let lastSampleTimestamp {
            let frameTime = timestamp - lastSampleTimestamp
            addMeasurement(id: .frame, timestamp: timestamp, value: frameTime)
        }
        if let counterSampleBuffer {
            let data = try counterSampleBuffer.resolveCounterRange(0 ..< 4)
            data?.withUnsafeBytes { buffer in
                let timestamps = buffer.bindMemory(to: MTLCounterResultTimestamp.self)
                addMeasurement(id: .vertexShader, timestamp: timestamp, value: timestamps[1].timestamp - timestamps[0].timestamp)
                addMeasurement(id: .fragmentShader, timestamp: timestamp, value: timestamps[3].timestamp - timestamps[2].timestamp)
            }
        }
        lastSampleTimestamp = timestamp
    }

    func addMeasurement(id: Measurement.Kind, timestamp: UInt64, value: UInt64) {
        measurements[id, default: .init(id: id, maxSamples: maxSamples)].addSample(timestamp: timestamp, value: value)
    }
}

private func getMachTimeInNanoseconds() -> UInt64 {
    var timebase = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    let currentTime = mach_absolute_time()
    return currentTime * UInt64(timebase.numer) / UInt64(timebase.denom)
}

// Move to RenderKitUI
public extension EnvironmentValues {
    @Entry
    var gpuCounters: GPUCounters?
}
