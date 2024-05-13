import Compute
import Metal

public struct BitonicSortDemo {
    public init() {
    }

    public func main() throws {
        let stopWatch = StopWatch()

        print("Creating random buffer", stopWatch)
        var entries: [UInt32] = (0 ..< 100_000).shuffled()

        print("Copying buffer to GPU.", stopWatch)
        let device = MTLCreateSystemDefaultDevice()!
        let numEntries = entries.count
        let buffer = entries.withUnsafeMutableBufferPointer { buffer in
            let buffer = UnsafeMutableRawBufferPointer(buffer)
            return device.makeBuffer(bytes: buffer.baseAddress!, length: buffer.count)!
        }
        print("Preparing compute.", stopWatch)

        print(Bundle.module.bundlePath)

        let function = ShaderLibrary.bundle(.module).bitonicSort
        let numStages = Int(log2(nextPowerOfTwo(Double(numEntries))))

        let compute = try Compute(device: device)

        var pass = try compute.makePass(function: function, arguments: [
            "numEntries": .int(numEntries),
            "entries": .buffer(buffer),
        ])

        let start = CFAbsoluteTimeGetCurrent()
        print("Running \(numStages) compute stages", stopWatch)

        var threadgroupsPerGrid = (entries.count + pass.maxTotalThreadsPerThreadgroup - 1) / pass.maxTotalThreadsPerThreadgroup
        threadgroupsPerGrid = (threadgroupsPerGrid + pass.threadExecutionWidth - 1) / pass.threadExecutionWidth * pass.threadExecutionWidth

        try compute.task { task in
            try task { dispatch in
                for stageIndex in 0 ..< numStages {
                    for stepIndex in 0 ..< (stageIndex + 1) {
                        let groupWidth = 1 << (stageIndex - stepIndex)
                        let groupHeight = 2 * groupWidth - 1

                        pass.arguments.groupWidth = .int(groupWidth)
                        pass.arguments.groupHeight = .int(groupHeight)
                        pass.arguments.stepIndex = .int(stepIndex)

                        try dispatch(
                            pass: pass,
                            threadgroupsPerGrid: MTLSize(width: threadgroupsPerGrid),
                            threadsPerThreadgroup: MTLSize(width: pass.maxTotalThreadsPerThreadgroup)
                        )
                    }
                }
            }
        }

        let current = CFAbsoluteTimeGetCurrent()
        print("GPU", current - start, 1 / (current - start))

        print("Running on CPU for comparison", stopWatch)
        let cpuTime = time() {
            entries.sort()
        }
        print("CPU", cpuTime)

        print("Confirming output is sorted", stopWatch)
        let sortedBuffer = UnsafeRawBufferPointer(start: buffer.contents(), count: buffer.length).bindMemory(to: UInt32.self)
        print("SORTED: *********", sortedBuffer.isSorted, "***************")
        print("Done", stopWatch)
    }
}
