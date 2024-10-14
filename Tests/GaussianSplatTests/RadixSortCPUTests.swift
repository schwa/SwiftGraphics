import BaseSupport
import Foundation
@testable import GaussianSplatSupport
import Testing

@Test
func cpuSortTest1() throws {
    struct Value: RadixSortable, Equatable {
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

        func key(shift: Int) -> Int {
            (Int(key) >> shift) & 0xFF
        }

    }

    var values = (0..<1_500_000).map { _ in let n = UInt32.random(in: 0..<UInt32.max); return Value(key: n, value: Float(n)) }
    let expectedResult = values.sorted { lhs, rhs in
        lhs.key < rhs.key
    }
    var temp = Array(repeating: Value(), count: values.count)
    values.withUnsafeMutableBufferPointer { values in
        temp.withUnsafeMutableBufferPointer { temp in
            RadixSortCPU<Value>().radixSort(input: values, temp: temp)
        }
    }
    #expect(values == expectedResult)
}

@Test
func cpuSortTest2() throws {
    struct Value: RadixSortable, Equatable {
        let value: Float
        init() {
            self.value = 0
        }

        init (value: Float) {
            self.value = value
        }

        func key(shift: Int) -> Int {
            let bits = value.bitPattern
            let signMask: UInt32 = 0x80000000
            let key: UInt32 = (bits & signMask != 0) ? ~bits : bits ^ signMask
            return (Int(key) >> shift) & 0xFF
        }
    }

    var values = (0..<1_500_000).map { _ in let n = Float.random(in: -1_000_000...1_000_000); return Value(value: Float(n)) }
    let expectedResult = timeit("Foundation Sort") {
         values.sorted { lhs, rhs in
            lhs.value < rhs.value
        }
    }
    var temp = Array(repeating: Value(), count: values.count)
    timeit("Radix Sort") {
        values.withUnsafeMutableBufferPointer { values in
            temp.withUnsafeMutableBufferPointer { temp in
                RadixSortCPU<Value>().radixSort(input: values, temp: temp)
            }
        }
    }
    #expect(values == expectedResult)
}

@Test
func testFloatToInt() {

    func float32ToUInt32Sortable(_ floatArray: [Float32]) -> [UInt32] {
        return floatArray.map { float in
            let bits = float.bitPattern
            let signMask: UInt32 = 0x80000000
            return (bits & signMask != 0) ? ~bits : bits ^ signMask
        }
    }

    // Example usage
    let inputArray: [Float32] = (0..<1_000_000).map { _ in Float32.random(in: -1_000_000...1_000_000) } + (0..<500_000).map { _ in Float32.random(in: -1...1) }
    let converted = float32ToUInt32Sortable(inputArray)

    // Verify that the sort order is preserved
    let originalSortOrder = inputArray.enumerated().sorted { $0.element < $1.element }.map { $0.offset }
    let convertedSortOrder = converted.enumerated().sorted { $0.element < $1.element }.map { $0.offset }

    #expect(originalSortOrder == convertedSortOrder)

    // Additional verification
//    print("Original min, max: \(inputArray.min()!), \(inputArray.max()!)")
//    print("Converted min, max: \(converted.min()!), \(converted.max()!)")
//    print("Sort order preserved: \(originalSortOrder == convertedSortOrder)")

}

@Test
func cpuSortTestStable() throws {
    struct Value: RadixSortable, Equatable {
        let key: UInt32
        let value: Float
        let index: Int

        init() {
            self.key = 0
            self.value = 0
            self.index = 0
        }

        init(key: UInt32, value: Float, index: Int) {
            self.key = key
            self.value = value
            self.index = index
        }

        func key(shift: Int) -> Int {
            (Int(key) >> shift) & 0xFF
        }

        static func ==(lhs: Value, rhs: Value) -> Bool {
            return lhs.key == rhs.key && lhs.value == rhs.value && lhs.index == rhs.index
        }
    }

    // Generate values with duplicate keys and unique indices
    var values = (0..<1_500_000).map { i in
        let n = UInt32.random(in: 0..<1000) // Limited range to create duplicates
        return Value(key: n, value: Float(n), index: i)
    }

    // Use a stable sort considering key and index
    let expectedResult = values.sorted { lhs, rhs in
        if lhs.key != rhs.key {
            return lhs.key < rhs.key
        } else {
            return lhs.index < rhs.index
        }
    }

    var temp = Array(repeating: Value(), count: values.count)
    values.withUnsafeMutableBufferPointer { values in
        temp.withUnsafeMutableBufferPointer { temp in
            RadixSortCPU<Value>().radixSort(input: values, temp: temp)
        }
    }

    // Verify that the radix sort is stable
    #expect(values == expectedResult)
}
