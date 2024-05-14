import CoreGraphics
import CoreGraphicsSupport
import Foundation
import LegacyGeometry

public extension Array2D {
    mutating func blit<SourceElement>(from source: Array2D<SourceElement>, frame: IntRect, to position: IntPoint, clip: IntRect? = nil, compositor: (_ source: SourceElement, _ destination: Element) -> Element) {
        let sourcePoints = IntRectSequence(rect: frame)
        let destinationPoints = IntRectSequence(rect: IntRect(origin: position, size: frame.size))

        for (sourcePoint, destinationPoint) in zip(sourcePoints, destinationPoints) {
            if let clip, !clip.contains(destinationPoint) {
                continue
            }
            let sourceElement = source[sourcePoint]
            let destinationElement = self[destinationPoint]
            let composited = compositor(sourceElement, destinationElement)
            self[destinationPoint] = composited
        }
    }

    mutating func blit(from source: Array2D, frame: IntRect, to position: IntPoint, clip: IntRect? = nil) {
        blit(from: source, frame: frame, to: position, clip: clip) { source, _ in
            source
        }
    }
}

public extension Array2D {
    func slice(for rect: IntRect) -> RectSlice {
        RectSlice(array: self, rect: rect)
    }

    struct RectSlice: Sequence {
        let array: Array2D
        let rect: IntRect

        __consuming public func makeIterator() -> RectIterator {
            RectIterator(array: array, rect: rect)
        }
    }

    struct RectIterator: IteratorProtocol {
        private let array: Array2D
        private let rect: IntRect

        private var x: Int
        private var y: Int

        init(array: Array2D, rect: IntRect) {
            self.array = array
            self.rect = rect

            x = rect.minX
            y = rect.minY
        }

        public mutating func next() -> Index? {
            if y == rect.maxY {
                return nil
            }
            let index = array.index([x, y])
            x += 1
            if x == rect.maxX {
                x = rect.minX
                y += 1
            }
            return index
        }
    }
}

public extension Array2D {
    init(rows: [[Element]]) {
        let rowLengths = rows.map(\.count)
        guard Set(rowLengths).count == 1 else {
            fatalError("Inconsistent lengths")
        }
        let size = IntSize(rows[0].count, rows.count)
        let flatStorage = Array(rows.joined())
        self.init(flatStorage: flatStorage, size: size)
    }

    init(rows: [[Element]], size: IntSize, missing: Element) {
        let paddedRows = rows.map { row in
            row + Array(repeatElement(missing, count: size.width - row.count))
        }
        let blankRow = Array(repeatElement(missing, count: size.width))
        let extendedRows = paddedRows + Array(repeatElement(blankRow, count: size.height - rows.count))
        let flatStorage = Array(extendedRows.joined())
        self.init(flatStorage: flatStorage, size: size)
    }
}

public extension Array2D {
    var indexRect: IntRect {
        IntRect(size: size)
    }
}

public extension Array2D {
    init(_ slice: RectSlice) {
        // TODO: There has to be a better way

        fatalError("Unimplemented")

        // self = Array2D(flatStorage: slice.map { slice.array[$0] }, size: slice.rect.size)
    }
}

public extension Array2D {
    func floodFill(_ index: Index, fill: (Index) -> Void, condition: (Index) -> Bool) {
        fill(index)
        for index in neighbours(of: index, includeDiagonal: true) where condition(index) {
            floodFill(index, fill: fill, condition: condition)
        }
    }
}

public extension Array2D {
    mutating func fillCircle(center: CGPoint, radius: CGFloat, value: Element) {
        for index in indices where center.distance(to: [Double(index.x), Double(index.y)]) < radius {
            self[index] = value
        }
    }
}

public extension Array2D where Element: Equatable {
    func magicWand(at start: Index) -> Array2D<Bool> {
        let searchElement = self[start]
        var result = Array2D<Bool>(repeating: false, size: size)
        func f(_ p: Array2DIndex) {
            if self[p] == searchElement && result[p] == false {
                result[p] = true
                for p in neighbours(of: p) {
                    f(p)
                }
            }
        }
        f(start)
        return result
    }

    func rect(containing element: Element) -> IntRect {
        var minX: Int = .max
        var maxX: Int = .min
        var minY: Int = .max
        var maxY: Int = .min
        for index in indices where self[index] == element {
            let p = index.point
            minX = Swift.min(minX, p.x)
            maxX = Swift.max(minX, p.x)
            minY = Swift.min(minY, p.y)
            maxY = Swift.max(minY, p.y)
        }
        return IntRect(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }
}
