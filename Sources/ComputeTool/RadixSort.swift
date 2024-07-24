import AppKit
import BaseSupport
import Compute
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import Metal
import MetalSupport
import MetalUnsafeConformances

func countingSort<T>(values: [T], valueSpace: Int, key: (T) -> Int) -> [T] where T: BinaryInteger {
    // Count
    var counts = values.reduce(into: Array(repeating: 0, count: valueSpace)) { result, value in
        result[key(value)] += 1
    }
    // Prefix Sum
    for i in counts.indices.dropFirst() {
        counts[i] += counts[i - 1]
    }
    // Shuffle
    var result = Array(repeating: T.zero, count: values.count)
    for i in values.indices.reversed() {
        let value = key(values[i])
        counts[value] -= 1
        result[counts[value]] = values[i]
    }
    return result
}

extension Collection where Element == UInt8 {
    func histogram() -> [Int] {
        reduce(into: Array(repeating: 0, count: 256)) { result, value in
            result[Int(value)] += 1
        }
    }
}

func radixSort(values: [Int]) -> [Int] {
    var values = values
    for n in 0..<4 {
        values = countingSort(values: values, valueSpace: 256) { ($0 >> (n * 8)) & 0xFF }
    }
    return values
}

// @main
// struct Test {
//    static func main() {
////        let values = [0, 3, 2, 2, 3, 2, 0, 3, 2, 1]
////        print(countingSort(values: values, valueSpace: 4, key: { $0 }))
//        let values = (0..<10).map { _ in Int.random(in: 0..<1_000_000_000) }
//        let result = radixSort(values: values)
//        assert(values.sorted() == result)
//    }
// }

struct RadixSort {
    let device = MTLCreateSystemDefaultDevice()!

    func makeLogState() throws -> MTLLogState {
        let logStateDescriptor = MTLLogStateDescriptor()
        logStateDescriptor.level = .debug
        logStateDescriptor.bufferSize = 128 * 1024 * 1024

        let logState = try device.makeLogState(descriptor: logStateDescriptor)
        logState.addLogHandler { _, _, _, message in
            print(message)
        }
        return logState
    }

    func main() throws {
        let values = (0..<5_000_000).map { _ in UInt32.random(in: 0...255) }
        let cpuCounts = timeit { values.map { UInt8($0) }.histogram() }

        let compute = try Compute(device: device, logState: try makeLogState())
        let library = ShaderLibrary.bundle(.module, name: "debug")

        var histogram = try compute.makePass(function: library.histogram)
        let counts = try device.makeBuffer(bytesOf: Array(repeating: UInt32.zero, count: 256), options: [])
        histogram.arguments.values = .buffer(try device.makeBuffer(bytesOf: values, options: []))
        histogram.arguments.valuesCount = .int(values.count)
        histogram.arguments.shift = .int(0)
        histogram.arguments.histogram = .buffer(counts)

        try timeit {
            try compute.task { task in
                try task { dispatch in
                    let maxTotalThreadsPerThreadgroup = histogram.computePipelineState.maxTotalThreadsPerThreadgroup
                    let threadExecutionWidth = histogram.computePipelineState.threadExecutionWidth
                    print(maxTotalThreadsPerThreadgroup)
                    try dispatch(pass: histogram, threads: MTLSize(width: 256, height: values.count), threadsPerThreadgroup: MTLSize(width: maxTotalThreadsPerThreadgroup, height: 1))
                }
            }
        }

        assert(cpuCounts == Array(counts.contentsBuffer(of: UInt32.self)).map(Int.init))

        print("GPU", Array(counts.contentsBuffer(of: UInt32.self))[0..<10])
        print("CPU", cpuCounts[..<10])
    }
}
