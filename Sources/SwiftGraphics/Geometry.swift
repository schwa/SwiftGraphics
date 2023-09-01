import Foundation

// TODO: What is this?

@available(*, deprecated, message: "Not sure who uses this")
struct Geometry {
    let width: Int
    let height: Int

    func index(x: Int, y: Int) -> Int {
        assert((0 ..< width).contains(x))
        assert((0 ..< height).contains(y))
        return x + width * y
    }

    struct Row: RandomAccessCollection {
        typealias Index = Int
        typealias Element = Int

        let geometry: Geometry
        let y: Int

        var startIndex: Int {
            0
        }

        var endIndex: Int {
            geometry.width
        }

        init(geometry: Geometry, y: Int) {
            self.geometry = geometry
            self.y = y
        }

        subscript(x: Int) -> Int {
            geometry.index(x: x, y: y)
        }
    }

    struct Column: RandomAccessCollection {
        typealias Index = Int
        typealias Element = Int

        let geometry: Geometry
        let x: Int

        var startIndex: Int {
            0
        }

        var endIndex: Int {
            geometry.height
        }

        init(geometry: Geometry, x: Int) {
            self.geometry = geometry
            self.x = x
        }

        subscript(y: Int) -> Int {
            geometry.index(x: x, y: y)
        }
    }

    func row(y: Int) -> Row {
        Row(geometry: self, y: y)
    }

    func column(x: Int) -> Column {
        Column(geometry: self, x: x)
    }
}
