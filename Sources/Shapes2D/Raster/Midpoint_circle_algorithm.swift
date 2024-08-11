import Foundation

//
// Adapted from https://en.wikipedia.org/wiki/Midpoint_circle_algorithm & https://web.archive.org/web/20120422045142/https://banu.com/blog/7/drawing-circles/
public func drawCircle(radius: Int, setPixel: (Int, Int) -> Void) {
    /* cos pi/4 = 185363 / 2^18 (approx) */
    let l = (radius * 185_363) >> 18
    let r2 = radius * radius

    /* At x=0, y=radius */
    var y = radius
    var y2 = radius * radius
    var ty = (2 * y) - 1
    var y2_new = r2 + 3

    for x in 0 ... l {
        y2_new -= (2 * x) - 3

        if (y2 - y2_new) >= ty {
            y2 -= ty
            y -= 1
            ty -= 2
        }

        setPixel(x, y)
        setPixel(x, -y)
        setPixel(-x, y)
        setPixel(-x, -y)

        setPixel(y, x)
        setPixel(y, -x)
        setPixel(-y, x)
        setPixel(-y, -x)
    }
}
