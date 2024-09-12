import Foundation

postfix operator ++

extension BinaryInteger {
    @available(*, deprecated, message: "Deprecated")
    static postfix func ++(rhs: inout Self) -> Self {
        let oldValue = rhs
        rhs += 1
        return oldValue
    }
}

// MARK: -

protocol PrefixSortable {
    var key: UInt32 { get }

    init()
}

struct RadixSortCPU <T> where T: PrefixSortable {

    func key(_ value: T, shift: Int) -> Int {
        (Int(value.key) >> shift) & 0xFF
    }

    func histogram(input: UnsafeMutableBufferPointer<T>, shift: Int) -> [UInt32] {
        input.reduce(into: Array(repeating: 0, count: 256)) { result, value in
            result[key(value, shift: shift)] += 1
        }
    }

    func prefixSumExclusive(_ input: [UInt32]) -> [UInt32] {
        input.prefixSumExclusive()
    }

    func shuffle(_ input: UnsafeMutableBufferPointer<T>, summedHistogram histogram: [UInt32], shift: Int, output: UnsafeMutableBufferPointer<T>) {
        var histogram = histogram
        for i in input.indices {
            let value = input[i]
            let key = key(value, shift: shift)
            let outputIndex = histogram[key]++
            output[Int(outputIndex)] = input[i]
        }
    }

    func countingSort(input: UnsafeMutableBufferPointer<T>, shift: Int, output: UnsafeMutableBufferPointer<T>) {
        let histogram = histogram(input: input, shift: shift)
        let summedHistogram = prefixSumExclusive(histogram)
        shuffle(input, summedHistogram: summedHistogram, shift: shift, output: output)
    }

    func radixSort(input: UnsafeMutableBufferPointer<T>, temp: UnsafeMutableBufferPointer<T>) {
        var input = input
        var temp = temp
        for phase in 0..<4 {
            countingSort(input: input, shift: phase * 8, output: temp)
            swap(&input, &temp)
        }
    }
}

// MARK: -

public extension Collection where Element: BinaryInteger {
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

struct Value: PrefixSortable, Equatable {
    let key: UInt32
    let value: Float

    init() {
        self.key = 0
        self.value = 0
    }

    init (key: UInt32, value: Float) {
        self.key = key
        self.value = value
    }
}

//var values = (0..<1_500_000).map { _ in let n = UInt32.random(in: 0..<UInt32.max); return Value(key: n, value: Float(n)) }
//let expectedResult = values.sorted { lhs, rhs in
//    lhs.key < rhs.key
//}
//
//var temp = Array(repeating: Value(), count: values.count)
//values.withUnsafeMutableBufferPointer { values in
//    temp.withUnsafeMutableBufferPointer { temp in
//        RadixSortCPU<Value>().radixSort(input: values, temp: temp)
//    }
//}
//
//print(values == expectedResult)
