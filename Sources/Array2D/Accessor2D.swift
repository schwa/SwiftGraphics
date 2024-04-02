//
import LegacyGeometry

// TODO: Reduce Storage requirements.
public struct Accessor2D<Storage> where Storage: RandomAccessCollection & MutableCollection, Storage.Index == Int {
    public private(set) var size: IntSize

    public typealias Element = Storage.Element

    public var flatStorage: Storage

//    public init(repeating: Element, size: IntSize) {
//        self.size = size
//        let flatCount = size.width * size.height
//        flatStorage = Storage(Array(repeating: repeating, count: flatCount))
//    }

    public init(flatStorage: Storage, size: IntSize) {
        self.size = size
        let flatCount = size.width * size.height
        precondition(flatCount == flatStorage.count)
        self.flatStorage = flatStorage
    }
}

// MARK: Sequence

extension Accessor2D: Sequence {
    public func makeIterator() -> Iterator {
        Iterator(array: self)
    }

    public struct Iterator: IteratorProtocol {
        let array: Accessor2D
        let startIndex: Accessor2D.Index
        let endIndex: Accessor2D.Index
        var currentIndex: Accessor2D.Index

        init(array: Accessor2D) {
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

extension Accessor2D: Collection {
    public struct Index {
        var flatIndex: Storage.Index
        let size: IntSize

        init(flatIndex: Storage.Index, size: IntSize) {
            assert(flatIndex >= 0)
            self.flatIndex = flatIndex
            self.size = size
        }
    }

    public var startIndex: Index {
        Index(x: 0, y: 0, size: size)
    }

    public var endIndex: Index {
        Index(flatIndex: size.width * size.height, size: size)
    }

    public subscript(index: Index) -> Element {
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

    public subscript(x: Int, y: Int) -> Element {
        get {
            self[Index(x: x, y: y, size: size)]
        }
        set {
            self[Index(x: x, y: y, size: size)] = newValue
        }
    }

    public func index(after i: Index) -> Index {
        var i = i
        i.flatIndex += 1
        return i
    }
}

// MARK: MutableCollection

extension Accessor2D: MutableCollection {
}

// MARK: BidirectionalCollection

extension Accessor2D: BidirectionalCollection {
    public func index(before i: Index) -> Index {
        fatalError("Unimplemented")
    }
}

// MARK: -

extension Accessor2D: RandomAccessCollection {
}

// MARK: -

public extension Accessor2D {
    func index(x: Int, y: Int) -> Index {
        Index(x: x, y: y, size: size)
    }
}

// MARK: -

public extension Accessor2D.Index {
    var x: Int {
        flatIndex % size.width
    }

    var y: Int {
        flatIndex / size.width
    }

    init(x: Int, y: Int, size: IntSize) {
        flatIndex = y * size.width + x
        self.size = size
    }
}

extension Accessor2D.Index: Equatable, Comparable, Hashable {
    public static func == (lhs: Accessor2D.Index, rhs: Accessor2D.Index) -> Bool {
        assert(lhs.size == rhs.size)
        return lhs.flatIndex == rhs.flatIndex
    }

    public static func < (lhs: Accessor2D.Index, rhs: Accessor2D.Index) -> Bool {
        assert(lhs.size == rhs.size)
        return lhs.flatIndex < rhs.flatIndex
    }
}

extension Accessor2D.Index: Strideable {
    public func distance(to other: Accessor2D.Index) -> Int {
        assert(size == other.size)
        return other.flatIndex - flatIndex
    }

    public func advanced(by n: Int) -> Accessor2D.Index {
        Accessor2D.Index(flatIndex: flatIndex + n, size: size)
    }
}

extension Accessor2D.Index: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y))"
    }
}

// MARK: -

public extension Accessor2D {
    subscript(point: IntPoint) -> Element {
        get {
            self[Index(x: point.x, y: point.y, size: size)]
        }
        set {
            self[Index(x: point.x, y: point.y, size: size)] = newValue
        }
    }
}

public extension Accessor2D.Index {
    var point: IntPoint {
        IntPoint(x: x, y: y)
    }
}
