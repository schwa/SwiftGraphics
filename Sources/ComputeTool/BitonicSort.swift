import Compute
import Metal
import MetalSupport
import os

// swiftlint:disable force_unwrapping

public struct BitonicSortDemo {
    let logger: Logger? = Logger()

    public init() {
    }

    public func main() throws {
        let stopWatch = StopWatch()

        logger?.debug("Creating random buffer", stopWatch)
        var entries: [UInt32] = (0 ..< 10_000).shuffled()

        logger?("Copying buffer to GPU.", stopWatch)
        let device = MTLCreateSystemDefaultDevice()!
        let numEntries = entries.count
        let buffer: MTLBuffer = try entries.withUnsafeMutableBufferPointer { buffer in
            let buffer = UnsafeMutableRawBufferPointer(buffer)
            return try device.makeBufferEx(bytes: buffer.baseAddress!, length: buffer.count)
        }
        logger?("Preparing compute.", stopWatch)

        let function = ShaderLibrary.bundle(.module).bitonicSort
        let numStages = Int(log2(nextPowerOfTwo(Double(numEntries))))

        let compute = try Compute(device: device)

        var pass = try compute.makePass(function: function, arguments: [
            "numEntries": .int(numEntries),
            "entries": .buffer(buffer),
        ])

        let start = CFAbsoluteTimeGetCurrent()
        logger?("Running \(numStages) compute stages", stopWatch)

        var threadgroupsPerGrid = (entries.count + pass.maxTotalThreadsPerThreadgroup - 1) / pass.maxTotalThreadsPerThreadgroup
        threadgroupsPerGrid = (threadgroupsPerGrid + pass.threadExecutionWidth - 1) / pass.threadExecutionWidth * pass.threadExecutionWidth

        try compute.task { task in
            try task { dispatch in
                var n = 0
                for stageIndex in 0 ..< numStages {
                    for stepIndex in 0 ..< (stageIndex + 1) {
                        let groupWidth = 1 << (stageIndex - stepIndex)
                        let groupHeight = 2 * groupWidth - 1

                        pass.arguments.groupWidth = .int(groupWidth)
                        pass.arguments.groupHeight = .int(groupHeight)
                        pass.arguments.stepIndex = .int(stepIndex)

                        logger?("\(n), \(stageIndex)/\(numStages), \(stepIndex)/\(stageIndex + 1), \(groupWidth), \(groupHeight)")
                        try dispatch(
                            pass: pass,
                            threadgroupsPerGrid: MTLSize(width: threadgroupsPerGrid),
                            threadsPerThreadgroup: MTLSize(width: pass.maxTotalThreadsPerThreadgroup)
                        )
                        n += 1
                    }
                }
            }
        }

        let current = CFAbsoluteTimeGetCurrent()
        logger?("GPU", current - start, 1 / (current - start))

        logger?("Running on CPU for comparison", stopWatch)
        let cpuTime = time {
            entries.sort()
        }
        logger?("CPU", cpuTime)

        logger?("Confirming output is sorted", stopWatch)
        let sortedBuffer = UnsafeRawBufferPointer(start: buffer.contents(), count: buffer.length).bindMemory(to: UInt32.self)
        logger?("SORTED: *********", sortedBuffer.isSorted, "***************")
        logger?("Done", stopWatch)
    }
}
