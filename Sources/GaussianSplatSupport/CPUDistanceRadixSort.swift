import Foundation

postfix operator ++

extension BinaryInteger {
    @available(*, deprecated, message: "Deprecated")
    static postfix func ++ (rhs: inout Self) -> Self {
        let oldValue = rhs
        rhs += 1
        return oldValue
    }
}

// MARK: -

internal protocol RadixSortable {
    func key(shift: Int) -> Int
}

internal struct RadixSortCPU <T> where T: RadixSortable {
    private func histogram(input: UnsafeMutableBufferPointer<T>, shift: Int) -> [UInt32] {
        input.reduce(into: Array(repeating: 0, count: 256)) { result, value in
            result[value.key(shift: shift)] += 1
        }
    }

    private func prefixSumExclusive(_ input: [UInt32]) -> [UInt32] {
        input.prefixSumExclusive()
    }

    private func shuffle(_ input: UnsafeMutableBufferPointer<T>, summedHistogram histogram: [UInt32], shift: Int, output: UnsafeMutableBufferPointer<T>) {
        assert(input.count <= output.count)
        var histogram = histogram
        for i in input.indices {
            let value = input[i]
            let key = value.key(shift: shift)
            let outputIndex = histogram[key]++
            assert(outputIndex < output.count)
            output[Int(outputIndex)] = input[i]
        }
    }

    internal func countingSort(input: UnsafeMutableBufferPointer<T>, shift: Int, output: UnsafeMutableBufferPointer<T>) {
        let histogram = histogram(input: input, shift: shift)
        let summedHistogram = prefixSumExclusive(histogram)
        shuffle(input, summedHistogram: summedHistogram, shift: shift, output: output)
    }

    internal func radixSort(input: UnsafeMutableBufferPointer<T>, temp: UnsafeMutableBufferPointer<T>) {
        var input = input
        var temp = temp
        for phase in 0..<4 {
            countingSort(input: input, shift: phase * 8, output: temp)
            swap(&input, &temp)
        }
    }
}

// MARK: -

internal extension Collection where Element: BinaryInteger {
    @inline(__always) func prefixSumInclusive() -> [Element] {
        reduce(into: []) { result, value in
            result.append((result.last ?? 0) + value)
        }
    }

    @inline(__always) func prefixSumExclusive() -> [Element] {
        reduce(into: [0]) { result, value in
            result.append(result.last! + value)
        }.dropLast()
    }
}
