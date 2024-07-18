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

    public struct Sample: Sendable {
        public var index: UInt64
        public var frameNanoseconds: UInt64
        public var vertexNanoseconds: UInt64?
        public var fragmentNanoseconds: UInt64?
    }

    @ObservationIgnored
    public private(set) var samples: [Sample] = []

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
        let now = getMachTimeInNanoseconds()
        let lastSample = samples.last
        var sample = Sample(index: (lastSample?.index ?? 0) + 1, frameNanoseconds: now - (lastSample?.frameNanoseconds ?? now))
        if let counterSampleBuffer {
            let data = try counterSampleBuffer.resolveCounterRange(0 ..< 4)
            data?.withUnsafeBytes { buffer in
                let timestamps = buffer.bindMemory(to: MTLCounterResultTimestamp.self)
                sample.vertexNanoseconds = timestamps[1].timestamp - timestamps[0].timestamp
                sample.fragmentNanoseconds = timestamps[3].timestamp - timestamps[2].timestamp
            }
        }
        samples.append(sample)
        samples = Array(samples.suffix(maxSamples))
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
