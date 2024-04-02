import Foundation
import LegacyGeometry

public func horizontalLine(start: IntPoint, length: Int, plot: (IntPoint) -> Void) {
    let range: CountableRange<Int> = length > 0 ? 0 ..< length : (0 + length) ..< 0
    for x in range {
        plot(IntPoint(x: start.x + x, y: start.y))
    }
}

public func verticalLine(start: IntPoint, length: Int, plot: (IntPoint) -> Void) {
    let range: CountableRange<Int> = length > 0 ? 0 ..< length : (0 + length) ..< 0
    for y in range {
        plot(IntPoint(x: start.x, y: start.y + y))
    }
}

public func line(start: IntPoint, end: IntPoint, plot: (IntPoint) -> Void) {
    if start == end {
        plot(start)
    }
    else if start.y == end.y {
        horizontalLine(start: start, length: end.x - start.x, plot: plot)
    }
    else if start.x == end.x {
        verticalLine(start: start, length: end.y - start.y, plot: plot)
    }
    else {
        bresenhamLine(start: start, end: end, plot: plot)
    }
}

public func bresenhamLine(start: IntPoint, end: IntPoint, plot: (IntPoint) -> Void) {
    var p0 = start
    var p1 = end

    let steep = abs(p1.y - p0.y) > abs(p1.x - p0.x)
    if steep {
        swap(&p0.x, &p0.y)
        swap(&p1.x, &p1.y)
    }
    if p0.x > p1.x {
        swap(&p0.x, &p1.x)
        swap(&p0.y, &p1.y)
    }
    let dX = p1.x - p0.x
    let dY = abs(p1.y - p0.y)
    var error = dX / 2
    let ystep = p0.y < p1.y ? 1 : -1
    var y = p0.y

    for x in p0.x ..< p1.x {
        if steep == false {
            plot(IntPoint(x: x, y: y))
        }
        else {
            plot(IntPoint(x: y, y: x))
        }
        error -= dY
        if error < 0 {
            y += ystep
            error += dX
        }
    }
}
