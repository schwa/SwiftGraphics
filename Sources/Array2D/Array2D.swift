import Foundation
import GenericGeometryBase

public struct Array2D<Element> {
    //    public enum Order {
    //        case columnMajor
    //        case rowMajor
    //    }

    // Always row major

    public private(set) var size: IntSize
    public var flatStorage: [Element]

    public init(repeating: Element, size: IntSize) {
        self.size = size
        let flatCount = size.width * size.height
        flatStorage = [Element](repeating: repeating, count: flatCount)
    }

    public init(flatStorage: [Element], size: IntSize) {
        self.size = size
        let flatCount = size.width * size.height
        precondition(flatCount == flatStorage.count)
        self.flatStorage = flatStorage
    }
}

// MARK: -

public extension Array2D {
    typealias Index = Array2DIndex

    var startIndex: Index {
        Index(x: 0, y: 0, size: size)
    }

    var endIndex: Index {
        Index(flatIndex: size.width * size.height, size: size)
    }

    subscript(index: Index) -> Element {
        get {
            assert(index.size == size)
            assert(index.flatIndex < flatStorage.count)
            return flatStorage[index.flatIndex]
        }
        set {
            assert(index.size == size)
            assert(index.flatIndex < flatStorage.count)
            flatStorage[index.flatIndex] = newValue
        }
    }

    subscript(x: Int, y: Int) -> Element {
        get {
            self[Index(x: x, y: y, size: size)]
        }
        set {
            self[Index(x: x, y: y, size: size)] = newValue
        }
    }
}

// Sequence

extension Array2D: Sequence {
    // Sequence

    public typealias Iterator = Array2DIterator

    public func makeIterator() -> Iterator {
        Array2DIterator(array: self)
    }

    public struct Array2DIterator: IteratorProtocol {
        let array: Array2D
        let startIndex: Array2D.Index
        let endIndex: Array2D.Index
        var currentIndex: Array2D.Index

        init(array: Array2D) {
            self.array = array
            startIndex = array.startIndex
            endIndex = array.endIndex
            currentIndex = startIndex
        }

        public mutating func next() -> Element? {
            guard currentIndex < endIndex else {
                return nil
            }
            let result = array[currentIndex]
            currentIndex.flatIndex += 1
            return result
        }
    }
}

// MARK: Collection

extension Array2D: Collection {
    public func index(after i: Index) -> Index {
        var i = i
        i.flatIndex += 1
        return i
    }
}

// MARK: MutableCollection

extension Array2D: MutableCollection {
}

// MARK: BidirectionalCollection

extension Array2D: BidirectionalCollection {
    // swiftlint:disable:next unavailable_function
    public func index(before i: Index) -> Index {
        fatalError("Unimplemented")
    }
}

// MARK: -

extension Array2D: RandomAccessCollection {
}

// MARK: -

extension Array2D: CustomStringConvertible {
    public var description: String {
        let body = rows.map { "[" + $0.map { String(describing: $0) }.joined(separator: ", ") + "]" }.joined(separator: ", ")

        return "\(type(of: self))(size: \(size), flatCount: \(flatStorage.count), rows: [\(body)]"
    }
}

// MARK: -

public extension Array2D {
    func index(_ point: IntPoint) -> Index {
        Index(x: point.x, y: point.y, size: size)
    }
}

// MARK: -

public struct Array2DIndex {
    public var x: Int {
        flatIndex % size.width
    }

    public var y: Int {
        flatIndex / size.width
    }

    public var flatIndex: Int
    public let size: IntSize

    public init(flatIndex: Int, size: IntSize) {
        assert(flatIndex >= 0)
        self.flatIndex = flatIndex
        self.size = size
    }

    public init(x: Int, y: Int, size: IntSize) {
        flatIndex = y * size.width + x
        self.size = size
    }
}

extension Array2DIndex: Equatable, Comparable, Hashable {
    public static func == (lhs: Array2DIndex, rhs: Array2DIndex) -> Bool {
        assert(lhs.size == rhs.size)
        return lhs.flatIndex == rhs.flatIndex
    }

    public static func < (lhs: Array2DIndex, rhs: Array2DIndex) -> Bool {
        assert(lhs.size == rhs.size)
        return lhs.flatIndex < rhs.flatIndex
    }
}

extension Array2DIndex: Strideable {
    public func distance(to other: Array2DIndex) -> Int {
        assert(size == other.size)
        return other.flatIndex - flatIndex
    }

    public func advanced(by n: Int) -> Array2DIndex {
        Array2DIndex(flatIndex: flatIndex + n, size: size)
    }
}

extension Array2DIndex: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y))"
    }
}

public extension Array2DIndex {
    var point: IntPoint {
        IntPoint(x: x, y: y)
    }
}

// MARK: -

public extension Array2D {
    subscript(point: IntPoint) -> Element {
        get {
            self[Index(x: point.x, y: point.y, size: size)]
        }
        set {
            self[Index(x: point.x, y: point.y, size: size)] = newValue
        }
    }
}
