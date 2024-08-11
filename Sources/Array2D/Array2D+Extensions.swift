import Algorithms
import Foundation
import GenericGeometryBase

public extension Array2D {
    var rows: [[Element]] {
        flatStorage.chunks(ofCount: size.width).map { Array($0) }
    }
}

public extension Array2D {
    func neighbours(of p: Index, includeDiagonal: Bool = false) -> [Index] {
        var offsets: [IntPoint] = [
            [-1, 0],
            [1, 0],
            [0, -1],
            [0, 1]
        ]
        if includeDiagonal {
            offsets += [
                [-1, -1],
                [-1, 1],
                [1, -1],
                [1, 1]
            ]
        }
        return offsets.map { p.point + $0 }
            .filter { IntRect(size: size).contains($0) }
            .map { index($0) }
    }

    mutating func set(mask: Array2D<Bool>, to element: Element) {
        for index in mask.indices where mask[index] == true {
            self[index.point] = element
        }
    }
}

public extension Array2D {
    init(size: IntSize, _ generator: (IntPoint) -> Element) {
        var flatStorage: [Element] = []
        for y in 0 ..< size.height {
            for x in 0 ..< size.width {
                flatStorage.append(generator(IntPoint(x: x, y: y)))
            }
        }
        self.init(flatStorage: flatStorage, size: size)
    }
}

public extension Array2D {
    enum Axis {
        case horizontal
        case vertical
    }

    func flipped(axis: Axis) -> Array2D {
        var result = self
        for index in indices {
            let location = index.point
            switch axis {
            case .vertical:
                result[size.width - location.x - 1, location.y] = self[location]
            case .horizontal:
                result[location.x, size.height - location.y - 1] = self[location]
            }
        }
        return result
    }
}
