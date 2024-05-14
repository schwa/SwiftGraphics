import simd

struct SpatialLookupTable<Positions> where Positions: Collection, Positions.Element == SIMD2<Float>, Positions.Index == Int {
    private(set) var size: SIMD2<Float>
    private(set) var radius: Float = 0
    private(set) var points: Positions!
    private var spatialLookup: [(index: Int, cellKey: Int)] = []
    private var startIndices: [Int] = []
    private let cellOffsets: [SIMD2<Int>] = [
        [-1, -1],
        [-1, 0],
        [-1, 1],
        [0, -1],
        [0, 0],
        [0, 1],
        [1, -1],
        [1, 0],
        [1, 1],
    ]

    init(size: SIMD2<Float>) {
        self.size = size
    }

    mutating func update(points: Positions, radius: Float) {
        self.points = points
        self.radius = radius
        // TODO: Combine this with later loop
        spatialLookup = Array(repeating: (-1, -1), count: points.count)
        startIndices = Array(repeating: .max, count: points.count)

        // Create (unordered) spatial lookup
        for i in points.startIndex ..< points.endIndex {
            let cell = positionToCellCoord(points[i], radius)
            let cellKey = key(for: cell)
            spatialLookup[i] = (i, cellKey)
            startIndices[i] = Int.max // Reset start index
        }

        // Sort by cell key
        spatialLookup.sort { lhs, rhs in
            lhs.cellKey < rhs.cellKey
        }

        // Calculate start indices of each unique cell key in the spatial lookup
        for i in points.startIndex ..< points.endIndex {
            let key = spatialLookup[i].cellKey
            let keyPrev = i == 0 ? Int.max : spatialLookup[i - 1].cellKey
            if key != keyPrev {
                startIndices[key] = i
            }
        }
    }

    private func positionToCellCoord(_ position: SIMD2<Float>, _ radius: Float) -> SIMD2<Int> {
        SIMD2<Int>(position / [radius, radius])
    }

    private func key(for cell: SIMD2<Int>) -> Int {
        // TODO: overflow
        let n = (cell.x * 15_823 + cell.y * 9_737_333)
        precondition(n >= 0)
        return n % spatialLookup.count
    }

    func indicesNear(point: SIMD2<Float>, hits: (Int) -> Void) {
        if radius == 0 {
            return
        }
        let xRange = 0 ..< Int(size.x / radius)
        let yRange = 0 ..< Int(size.y / radius)
        // Find which cell the sample point is in (this will be the centre of our 3x3 block)
        let center = positionToCellCoord(point, radius)
        let sqrRadius = radius * radius
        // Loop over all cells of the 3x3 block around the centre cell
        for offset in cellOffsets {
            // Get key of current cell, then loop over all points that share that key
            let cell = center &+ offset
            guard xRange.contains(cell.x), yRange.contains(cell.y) else {
                continue
            }
            let key = key(for: cell)
            let cellStartIndex = startIndices[key]
            if cellStartIndex == .max {
                continue
            }
            for i in cellStartIndex ..< spatialLookup.count {
                // Exit loop if we're no longer looking at the correct cell
                if spatialLookup[i].cellKey != key { break }
                let particleIndex = spatialLookup[i].index
                let sqrDst = distance_squared(points[particleIndex], point)
                // Test if the point is inside the radius
                if sqrDst <= sqrRadius {
                    // Do something with the particleIndex!
                    // (either by writing code here that uses it directly, or more likely by
                    // having this function take in a callback, or return an IEnumerable, etc.)
                    hits(particleIndex)
                }
            }
        }
    }
}

extension SpatialLookupTable {
    func indicesNear(point: SIMD2<Float>) -> Set<Int> {
        var indices: Set<Int> = []
        indicesNear(point: point, hits: {
            indices.insert($0)
        })
        return indices
    }

    func indicesNear(index: Int, hits: (Int) -> Void) {
        let point = points[index]
        indicesNear(point: point, hits: hits)
    }

    func indicesNear(index: Int) -> Set<Int> {
        let point = points[index]
        return indicesNear(point: point)
    }
}
