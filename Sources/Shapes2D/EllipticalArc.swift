// periphery:ignore:all
// swiftlint:disable type_body_length
// swiftlint:disable function_parameter_count
// swiftlint:disable multiline_parameters
// swiftlint:disable indentation_width
// swiftlint:disable implicitly_unwrapped_optional
// Sense a theme here?:

import CoreGraphics
import SwiftUI

// /* This class represents an elliptical arc on a 2D plane.
//
//  * <p>It is designed as an implementation of the
//  * <code>java.awt.Shape</code> interface and can therefore be drawn
//  * easily as any of the more traditional shapes provided by the
//  * standard Java API.</p>
//
//  * <p>This class differs from the <code>java.awt.geom.Ellipse2D</code>
//  * in the fact it can handles parts of ellipse in addition to full
//  * ellipses and it can handle ellipses which are not aligned with the
//  * x and y reference axes of the plane. <p>
//
//  * <p>Another improvement is that this class can handle degenerated
//  * cases like for example very flat ellipses (semi-minor axis much
//  * smaller than semi-major axis) and drawing of very small parts of
//  * such ellipses at very high magnification scales. This imply
//  * monitoring the drawing approximation error for extremely small
//  * values. Such cases occur for example while drawing orbits of comets
//  * near the perihelion.</p>
//
//  * <p>When the arc does not cover the complete ellipse, the lines
//  * joining the center of the ellipse to the endpoints can optionally
//  * be included or not in the outline, hence allowing to use it for
//  * pie-charts rendering. If these lines are not included, the curve is
//  * not naturally closed.</p>
//
//  * @author L. Maisonobe
//  */

private let twoPi = 2 * Double.pi

public class EllipticalArc {
    // coefficients for error estimation
    // while using quadratic Bézier curves for approximation
    // 0 < b/a < 1/4
    private static let coeffs2Low = [
        [
            [3.92478, -13.5822, -0.233377, 0.0128206],
            [-1.08814, 0.859987, 0.000362265, 0.000229036],
            [-0.942512, 0.390456, 0.0080909, 0.00723895],
            [-0.736228, 0.20998, 0.0129867, 0.0103456],
        ],
        [
            [-0.395018, 6.82464, 0.0995293, 0.0122198],
            [-0.545608, 0.0774863, 0.0267327, 0.0132482],
            [0.0534754, -0.0884167, 0.012595, 0.0343396],
            [0.209052, -0.0599987, -0.00723897, 0.00789976],
        ],
    ]

    // coefficients for error estimation
    // while using quadratic Bézier curves for approximation
    // 1/4 <= b/a <= 1
    private static let coeffs2High = [
        [
            [0.0863805, -11.5595, -2.68765, 0.181224],
            [0.242856, -1.81073, 1.56876, 1.68544],
            [0.233337, -0.455621, 0.222856, 0.403469],
            [0.0612978, -0.104879, 0.0446799, 0.00867312],
        ],
        [
            [0.028973, 6.68407, 0.171472, 0.0211706],
            [0.0307674, -0.0517815, 0.0216803, -0.0749348],
            [-0.0471179, 0.1288, -0.0781702, 2.0],
            [-0.0309683, 0.0531557, -0.0227191, 0.0434511],
        ],
    ]

    // safety factor to convert the "best" error approximation
    // into a "max bound" error
    private static let safety2 = [
        0.02, 2.83, 0.125, 0.01,
    ]

    // coefficients for error estimation
    // while using cubic Bézier curves for approximation
    // 0 < b/a < 1/4
    private static let coeffs3Low = [
        [
            [3.85268, -21.229, -0.330434, 0.0127842],
            [-1.61486, 0.706564, 0.225945, 0.263682],
            [-0.910164, 0.388383, 0.00551445, 0.00671814],
            [-0.630184, 0.192402, 0.0098871, 0.0102527],
        ],
        [
            [-0.162211, 9.94329, 0.13723, 0.0124084],
            [-0.253135, 0.00187735, 0.0230286, 0.01264],
            [-0.0695069, -0.0437594, 0.0120636, 0.0163087],
            [-0.0328856, -0.00926032, -0.00173573, 0.00527385],
        ],
    ]

    // coefficients for error estimation
    // while using cubic Bézier curves for approximation
    // 1/4 <= b/a <= 1
    private static let coeffs3High = [
        [
            [0.0899116, -19.2349, -4.11711, 0.183362],
            [0.138148, -1.45804, 1.32044, 1.38474],
            [0.230903, -0.450262, 0.219963, 0.414038],
            [0.0590565, -0.101062, 0.0430592, 0.0204699],
        ],
        [
            [0.0164649, 9.89394, 0.0919496, 0.00760802],
            [0.0191603, -0.0322058, 0.0134667, -0.0825018],
            [0.0156192, -0.017535, 0.00326508, -0.228157],
            [-0.0236752, 0.0405821, -0.0173086, 0.176187],
        ],
    ]

    // safety factor to convert the "best" error approximation
    // into a "max bound" error
    private static let safety3 = [
        0.001, 4.98, 0.207, 0.0067,
    ]

    /* Abscissa of the center of the ellipse. */
    let cx: Double

    /* Ordinate of the center of the ellipse. */
    let cy: Double

    /* Semi-major axis. */
    let a: Double

    /* Semi-minor axis. */
    let b: Double

    /* Orientation of the major axis with respect to the x axis. */
    let theta: Double
    private let cosTheta: Double
    private let sinTheta: Double

    /* Start angle of the arc. */
    let eta1: Double

    /* End angle of the arc. */
    var eta2: Double

    /* Abscissa of the start point. */
    var x1: Double!

    /* Ordinate of the start point. */
    var y1: Double!

    /* Abscissa of the end point. */
    var x2: Double!

    /* Ordinate of the end point. */
    var y2: Double!

    /* Abscissa of the first focus. */
    var xF1: Double!

    /* Ordinate of the first focus. */
    var yF1: Double!

    /* Abscissa of the second focus. */
    var xF2: Double!

    /* Ordinate of the second focus. */
    var yF2: Double!

    /* Abscissa of the leftmost point of the arc. */
    private var xLeft: Double!

    /* Ordinate of the highest point of the arc. */
    private var yUp: Double!

    /* Horizontal width of the arc. */
    private var width: Double!

    /* Vertical height of the arc. */
    private var height: Double!

    /* Indicator for center to endpoints line inclusion. */
    let isPieSlice: Bool

    /* Maximal degree for Bézier curve approximation. */
    private let maxDegree: Int

    /* Default flatness for Bézier curve approximation. */
    private let defaultFlatness: Double

    var f: Double!
    var e2: Double!
    var g: Double!
    var g2: Double!

    public init() {
        cx = 0
        cy = 0
        a = 1
        b = 1
        theta = 0
        eta1 = 0
        eta2 = 2 * .pi
        cosTheta = 1
        sinTheta = 0
        isPieSlice = false
        maxDegree = 3
        defaultFlatness = 0.5 // half a pixel

        computeFocii()
        computeEndPoints()
        computeBounds()
        computeDerivedFlatnessParameters()
    }

    /* Build an elliptical arc from its canonical geometrical elements.
     * @param center center of the ellipse
     * @param a semi-major axis
     * @param b semi-minor axis
     * @param theta orientation of the major axis with respect to the x axis
     * @param lambda1 start angle of the arc
     * @param lambda2 end angle of the arc
     * @param isPieSlice if true, the lines between the center of the ellipse
     * and the endpoints are part of the shape (it is pie slice like)
     */
    public convenience init(center: CGPoint, a: Double, b: Double,
                            theta: Double, lambda1: Double, lambda2: Double,
                            isPieSlice: Bool) {
        self.init(cx: Double(center.x), cy: Double(center.y), a: a, b: b, theta: theta, lambda1: lambda1, lambda2: lambda2, isPieSlice: isPieSlice)
    }

    /* Build an elliptical arc from its canonical geometrical elements.
     * @param cx abscissa of the center of the ellipse
     * @param cy ordinate of the center of the ellipse
     * @param a semi-major axis
     * @param b semi-minor axis
     * @param theta orientation of the major axis with respect to the x axis
     * @param lambda1 start angle of the arc
     * @param lambda2 end angle of the arc
     * @param isPieSlice if true, the lines between the center of the ellipse
     * and the endpoints are part of the shape (it is pie slice like)
     */
    public init(cx: Double, cy: Double, a: Double, b: Double,
                theta: Double, lambda1: Double, lambda2: Double,
                isPieSlice: Bool) {
        self.cx = cx
        self.cy = cy
        self.a = a
        self.b = b
        self.theta = theta
        self.isPieSlice = isPieSlice

        eta1 = atan2(sin(lambda1) / b,
                     cos(lambda1) / a)
        eta2 = atan2(sin(lambda2) / b,
                     cos(lambda2) / a)
        cosTheta = cos(theta)
        sinTheta = sin(theta)
        maxDegree = 3
        defaultFlatness = 0.5 // half a pixel

        // make sure we have eta1 <= eta2 <= eta1 + 2 PI
        eta2 -= twoPi * floor((eta2 - eta1) / twoPi)

        // the preceding correction fails if we have exactly et2 - eta1 = 2 PI
        // it reduces the interval to zero length
        if (lambda2 - lambda1 > .pi) && (eta2 - eta1 < .pi) {
            eta2 += 2 * .pi
        }

        computeFocii()
        computeEndPoints()
        computeBounds()
        computeDerivedFlatnessParameters()
    }

    /* Build a full ellipse from its canonical geometrical elements.
     * @param center center of the ellipse
     * @param a semi-major axis
     * @param b semi-minor axis
     * @param theta orientation of the major axis with respect to the x axis
     */
    public convenience init(center: CGPoint, a: Double, b: Double, theta: Double) {
        self.init(cx: Double(center.x), cy: Double(center.y), a: a, b: b, theta: theta)
    }

    /* Build a full ellipse from its canonical geometrical elements.
     * @param cx abscissa of the center of the ellipse
     * @param cy ordinate of the center of the ellipse
     * @param a semi-major axis
     * @param b semi-minor axis
     * @param theta orientation of the major axis with respect to the x axis
     */
    public init(cx: Double, cy: Double, a: Double, b: Double, theta: Double) {
        self.cx = cx
        self.cy = cy
        self.a = a
        self.b = b
        self.theta = theta
        isPieSlice = false

        eta1 = 0
        eta2 = 2 * .pi
        cosTheta = cos(theta)
        sinTheta = sin(theta)
        maxDegree = 3
        defaultFlatness = 0.5 // half a pixel

        computeFocii()
        computeEndPoints()
        computeBounds()
        computeDerivedFlatnessParameters()
    }

    //   /** Set the maximal degree allowed for Bézier curve approximation.
    //    * @param maxDegree maximal allowed degree (must be between 1 and 3)
    //    * @exception IllegalArgumentException if maxDegree is not between 1 and 3
    //    */
    //   public void setMaxDegree(int maxDegree) {
    //     if ((maxDegree < 1) || (maxDegree > 3)) {
    //       throw new IllegalArgumentException("maxDegree must be between 1 and 3")
    //     }
    //     this.maxDegree = maxDegree
    //   }

    //   /* Set the default flatness for Bézier curve approximation.
    //    * @param defaultFlatness default flatness (must be greater than 1.0e-10)
    //    * @exception IllegalArgumentException if defaultFlatness is lower
    //    * than 1.0e-10
    //    */
    //   public void setDefaultFlatness(double defaultFlatness) {
    //     if (defaultFlatness < 1.0e-10) {
    //       throw new IllegalArgumentException("defaultFlatness must be"
    //                                          + " greater than 1.0e-10")
    //     }
    //     this.defaultFlatness = defaultFlatness
    //   }

    /* Compute the locations of the focii. */
    private func computeFocii() {
        let d = sqrt(a * a - b * b)
        let dx = d * cosTheta
        let dy = d * sinTheta

        xF1 = cx - dx
        yF1 = cy - dy
        xF2 = cx + dx
        yF2 = cy + dy
    }

    /* Compute the locations of the endpoints. */
    private func computeEndPoints() {
        // start point
        let aCosEta1 = a * cos(eta1)
        let bSinEta1 = b * sin(eta1)
        x1 = cx + aCosEta1 * cosTheta - bSinEta1 * sinTheta
        y1 = cy + aCosEta1 * sinTheta + bSinEta1 * cosTheta

        // end point
        let aCosEta2 = a * cos(eta2)
        let bSinEta2 = b * sin(eta2)
        x2 = cx + aCosEta2 * cosTheta - bSinEta2 * sinTheta
        y2 = cy + aCosEta2 * sinTheta + bSinEta2 * cosTheta
    }

    /* Compute the bounding box. */
    private func computeBounds() {
        let bOnA = b / a
        var etaXMin: Double, etaXMax: Double, etaYMin: Double, etaYMax: Double
        if abs(sinTheta) < 0.1 {
            let tanTheta = sinTheta / cosTheta
            if cosTheta < 0 {
                etaXMin = -atan(tanTheta * bOnA)
                etaXMax = etaXMin + .pi
                etaYMin = 0.5 * .pi - atan(tanTheta / bOnA)
                etaYMax = etaYMin + .pi
            }
            else {
                etaXMax = -atan(tanTheta * bOnA)
                etaXMin = etaXMax - .pi
                etaYMax = 0.5 * .pi - atan(tanTheta / bOnA)
                etaYMin = etaYMax - .pi
            }
        }
        else {
            let invTanTheta = cosTheta / sinTheta
            if sinTheta < 0 {
                etaXMax = 0.5 * .pi + atan(invTanTheta / bOnA)
                etaXMin = etaXMax - .pi
                etaYMin = atan(invTanTheta * bOnA)
                etaYMax = etaYMin + .pi
            }
            else {
                etaXMin = 0.5 * .pi + atan(invTanTheta / bOnA)
                etaXMax = etaXMin + .pi
                etaYMax = atan(invTanTheta * bOnA)
                etaYMin = etaYMax - .pi
            }
        }

        etaXMin -= twoPi * floor((etaXMin - eta1) / twoPi)
        etaYMin -= twoPi * floor((etaYMin - eta1) / twoPi)
        etaXMax -= twoPi * floor((etaXMax - eta1) / twoPi)
        etaYMax -= twoPi * floor((etaYMax - eta1) / twoPi)

        xLeft = (etaXMin <= eta2)
            ? (cx + a * cos(etaXMin) * cosTheta - b * sin(etaXMin) * sinTheta)
            : min(x1, x2)
        yUp = (etaYMin <= eta2)
            ? (cy + a * cos(etaYMin) * sinTheta + b * sin(etaYMin) * cosTheta)
            : min(y1, y2)
        width = ((etaXMax <= eta2)
                    ? (cx + a * cos(etaXMax) * cosTheta - b * sin(etaXMax) * sinTheta)
                    : max(x1, x2)) - xLeft
        height = ((etaYMax <= eta2)
                    ? (cy + a * cos(etaYMax) * sinTheta + b * sin(etaYMax) * cosTheta)
                    : max(y1, y2)) - yUp
    }

    private func computeDerivedFlatnessParameters() {
        f = (a - b) / a
        e2 = f * (2.0 - f)
        g = 1.0 - f
        g2 = g * g
    }

    /* Compute the value of a rational function.
     * This method handles rational functions where the numerator is
     * quadratic and the denominator is linear
     * @param x absissa for which the value should be computed
     * @param c coefficients array of the rational function
     */
    private func rationalFunction(_ x: Double, _ c: [Double]) -> Double {
        (x * (x * c[0] + c[1]) + c[2]) / (x + c[3])
    }

    /* Estimate the approximation error for a sub-arc of the instance.
     * @param degree degree of the Bézier curve to use (1, 2 or 3)
     * @param tA start angle of the sub-arc
     * @param tB end angle of the sub-arc
     * @return upper bound of the approximation error between the Bézier
     * curve and the real ellipse
     */
    func estimateError(_ degree: Int, _ etaA: Double, _ etaB: Double) -> Double {
        let eta = 0.5 * (etaA + etaB)

        if degree < 2 {
            // start point
            let aCosEtaA = a * cos(etaA)
            let bSinEtaA = b * sin(etaA)
            let xA = cx + aCosEtaA * cosTheta - bSinEtaA * sinTheta
            let yA = cy + aCosEtaA * sinTheta + bSinEtaA * cosTheta

            // end point
            let aCosEtaB = a * cos(etaB)
            let bSinEtaB = b * sin(etaB)
            let xB = cx + aCosEtaB * cosTheta - bSinEtaB * sinTheta
            let yB = cy + aCosEtaB * sinTheta + bSinEtaB * cosTheta

            // maximal error point
            let aCosEta = a * cos(eta)
            let bSinEta = b * sin(eta)
            let x = cx + aCosEta * cosTheta - bSinEta * sinTheta
            let y = cy + aCosEta * sinTheta + bSinEta * cosTheta

            let dx = xB - xA
            let dy = yB - yA

            return abs(x * dy - y * dx + xB * yA - xA * yB)
                / sqrt(dx * dx + dy * dy)
        }
        else {
            let x = b / a
            let dEta = etaB - etaA
            let cos2 = cos(2 * eta)
            let cos4 = cos(4 * eta)
            let cos6 = cos(6 * eta)

            // select the right coeficients set according to degree and b/a
            let coeffs: [[[Double]]]
            // swiftlint:enable syntactic_sugar
            let safety: [Double]
            if degree == 2 {
                coeffs = (x < 0.25) ? Self.coeffs2Low : Self.coeffs2High
                safety = Self.safety2
            }
            else {
                coeffs = (x < 0.25) ? Self.coeffs3Low : Self.coeffs3High
                safety = Self.safety3
            }

            let c0 = rationalFunction(x, coeffs[0][0])
                + cos2 * rationalFunction(x, coeffs[0][1])
                + cos4 * rationalFunction(x, coeffs[0][2])
                + cos6 * rationalFunction(x, coeffs[0][3])

            let c1 = rationalFunction(x, coeffs[1][0])
                + cos2 * rationalFunction(x, coeffs[1][1])
                + cos4 * rationalFunction(x, coeffs[1][2])
                + cos6 * rationalFunction(x, coeffs[1][3])

            return rationalFunction(x, safety) * a * exp(c0 + c1 * dEta)
        }
    }

    /* Get the elliptical arc point for a given angular parameter.
     * @param lambda angular parameter for which point is desired
     * @param p placeholder where to put the point, if null a new Point
     * well be allocated
     * @return the object p or a new object if p was null, set to the
     * desired elliptical arc point location
     */
    public func pointAt(_ lambda: Double) -> CGPoint {
        let eta = atan2(sin(lambda) / b, cos(lambda) / a)
        let aCosEta = a * cos(eta)
        let bSinEta = b * sin(eta)

        return CGPoint(x: cx + aCosEta * cosTheta - bSinEta * sinTheta,
                       y: cy + aCosEta * sinTheta + bSinEta * cosTheta)
    }

    /* Tests if the specified coordinates are inside the boundary of the Shape.
     * @param x abscissa of the test point
     * @param y ordinate of the test point
     * @return true if the specified coordinates are inside the Shape
     * boundary; false otherwise
     */
    public func contains(_ x: Double, _ y: Double) -> Bool {
        // position relative to the focii
        let dx1 = x - xF1
        let dy1 = y - yF1
        let dx2 = x - xF2
        let dy2 = y - yF2
        if (dx1 * dx1 + dy1 * dy1 + dx2 * dx2 + dy2 * dy2) > (4 * a * a) {
            // the point is outside of the ellipse
            return false
        }

        if isPieSlice {
            // check the location of the test point with respect to the
            // angular sector counted from the center of the ellipse
            let dxC = x - cx
            let dyC = y - cy
            let u = dxC * cosTheta + dyC * sinTheta
            let v = dyC * cosTheta - dxC * sinTheta
            var eta = atan2(v / b, u / a)
            eta -= twoPi * floor((eta - eta1) / twoPi)
            return (eta <= eta2)
        }
        else {
            // check the location of the test point with respect to the
            // line joining the start and end points
            let dx = x2 - x1
            let dy = y2 - y1

            let t1 = x * dy - y * dx
            let t2 = x2 * y1 - x1 * y2
            let t = t1 + t2
            return t >= 0
        }
    }

    /* Tests if a line segment intersects the arc.
     * @param xA abscissa of the first point of the line segment
     * @param yA ordinate of the first point of the line segment
     * @param xB abscissa of the second point of the line segment
     * @param yB ordinate of the second point of the line segment
     * @return true if the two line segments intersect
     */
    private func intersectArc(_ xA: Double, _ yA: Double,
                              _ xB: Double, _ yB: Double) -> Bool {
        var dx = xA - xB
        var dy = yA - yB
        let l = sqrt(dx * dx + dy * dy)
        if l < (1.0e-10 * a) {
            // too small line segment, we consider it doesn't intersect anything
            return false
        }
        let cz = (dx * cosTheta + dy * sinTheta) / l
        let sz = (dy * cosTheta - dx * sinTheta) / l

        // express position of the first point in canonical frame
        dx = xA - cx
        dy = yA - cy
        let u = dx * cosTheta + dy * sinTheta
        let v = dy * cosTheta - dx * sinTheta

        let u2 = u * u
        let v2 = v * v
        let g2u2ma2 = g2 * (u2 - a * a)
        // let g2u2ma2mv2 = g2u2ma2 - v2 // Never used
        let g2u2ma2pv2 = g2u2ma2 + v2

        // compute intersections with the ellipse along the line
        // as the roots of a 2nd degree polynom : c0 k^2 - 2 c1 k + c2 = 0
        let c0 = 1.0 - e2 * cz * cz
        let c1 = g2 * u * cz + v * sz
        let c2 = g2u2ma2pv2
        let c12 = c1 * c1
        let c0c2 = c0 * c2

        if c12 < c0c2 {
            // the line does not intersect the ellipse at all
            return false
        }

        var k = (c1 >= 0)
            ? (c1 + sqrt(c12 - c0c2)) / c0
            : c2 / (c1 - sqrt(c12 - c0c2))
        if (k >= 0) && (k <= l) {
            let uIntersect = u - k * cz
            let vIntersect = v - k * sz
            var eta = atan2(vIntersect / b, uIntersect / a)
            eta -= twoPi * floor((eta - eta1) / twoPi)
            if eta <= eta2 {
                return true
            }
        }

        k = c2 / (k * c0)
        if (k >= 0) && (k <= l) {
            let uIntersect = u - k * cz
            let vIntersect = v - k * sz
            var eta = atan2(vIntersect / b, uIntersect / a)
            eta -= twoPi * floor((eta - eta1) / twoPi)
            if eta <= eta2 {
                return true
            }
        }

        return false
    }

    /* Tests if two line segments intersect.
     * @param x1 abscissa of the first point of the first line segment
     * @param y1 ordinate of the first point of the first line segment
     * @param x2 abscissa of the second point of the first line segment
     * @param y2 ordinate of the second point of the first line segment
     * @param xA abscissa of the first point of the second line segment
     * @param yA ordinate of the first point of the second line segment
     * @param xB abscissa of the second point of the second line segment
     * @param yB ordinate of the second point of the second line segment
     * @return true if the two line segments intersect
     */
    private static func intersect(_ x1: Double, _ y1: Double,
                                  _ x2: Double, _ y2: Double,
                                  _ xA: Double, _ yA: Double,
                                  _ xB: Double, _ yB: Double) -> Bool {
        // elements of the equation of the (1, 2) line segment
        let dx12 = x2 - x1
        let dy12 = y2 - y1
        let k12 = x2 * y1 - x1 * y2

        // elements of the equation of the (A, B) line segment
        let dxAB = xB - xA
        let dyAB = yB - yA
        let kAB = xB * yA - xA * yB

        // compute relative positions of endpoints versus line segments
        let pAvs12 = xA * dy12 - yA * dx12 + k12
        let pBvs12 = xB * dy12 - yB * dx12 + k12
        let p1vsAB = x1 * dyAB - y1 * dxAB + kAB
        let p2vsAB = x2 * dyAB - y2 * dxAB + kAB

        return (pAvs12 * pBvs12 <= 0) && (p1vsAB * p2vsAB <= 0)
    }

    /* Tests if a line segment intersects the outline.
     * @param xA abscissa of the first point of the line segment
     * @param yA ordinate of the first point of the line segment
     * @param xB abscissa of the second point of the line segment
     * @param yB ordinate of the second point of the line segment
     * @return true if the two line segments intersect
     */
    private func intersectOutline(_ xA: Double, _ yA: Double,
                                  _ xB: Double, _ yB: Double) -> Bool {
        if intersectArc(xA, yA, xB, yB) {
            return true
        }

        if isPieSlice {
            return (Self.intersect(cx, cy, x1, y1, xA, yA, xB, yB)
                        || Self.intersect(cx, cy, x2, y2, xA, yA, xB, yB))
        }
        else {
            return Self.intersect(x1, y1, x2, y2, xA, yA, xB, yB)
        }
    }

    /* Tests if the interior of the Shape entirely contains the
     * specified rectangular area.
     * @param x abscissa of the upper-left corner of the test rectangle
     * @param y ordinate of the upper-left corner of the test rectangle
     * @param w width of the test rectangle
     * @param h height of the test rectangle
     * @return true if the interior of the Shape entirely contains the
     * specified rectangular area; false otherwise
     */
    public func contains(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Bool {
        let xPlusW = x + w
        let yPlusH = y + h
        return (contains(x, y)
                    && contains(xPlusW, y)
                    && contains(x, yPlusH)
                    && contains(xPlusW, yPlusH)
                    && (!intersectOutline(x, y, xPlusW, y))
                    && (!intersectOutline(xPlusW, y, xPlusW, yPlusH))
                    && (!intersectOutline(xPlusW, yPlusH, x, yPlusH))
                    && (!intersectOutline(x, yPlusH, x, y)))
    }

    /* Tests if a specified Point2D is inside the boundary of the Shape.
     * @param p test point
     * @return true if the specified point is inside the Shape
     * boundary; false otherwise
     */
    public func contains(_ p: CGPoint) -> Bool {
        contains(Double(p.x), Double(p.y))
    }

    /* Tests if the interior of the Shape entirely contains the
     * specified Rectangle2D.
     * @param r test rectangle
     * @return true if the interior of the Shape entirely contains the
     * specified rectangular area; false otherwise
     */
    public func contains(r: CGRect) -> Bool {
        contains(Double(r.minX), Double(r.minY), Double(r.width), Double(r.height))
    }

    /* Returns an integer Rectangle that completely encloses the Shape.
     */
    public func getBounds() -> CGRect {
        let xMin = round(xLeft - 0.5)
        let yMin = round(yUp - 0.5)
        let xMax = round(xLeft + width + 0.5)
        let yMax = round(yUp + height + 0.5)
        return CGRect(x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin)
    }

    /* Returns a high precision and more accurate bounding box of the
     * Shape than the getBounds method.
     */
    public func getBounds2D() -> CGRect {
        CGRect(x: xLeft, y: yUp, width: width, height: height)
    }

    /* Build an approximation of the instance outline.
     * @param degree degree of the Bézier curve to use
     * @param threshold acceptable error
     * @return a path iterator
     */
    public func buildPathIterator(degree: Int, threshold: Double) -> Path {
        // find the number of Bézier curves needed
        var found = false
        var n = 1
        while (!found) && (n < 1_024) {
            let dEta = (eta2 - eta1) / Double(n)
            if dEta <= 0.5 * .pi {
                var etaB = eta1
                found = true

                for _ in 0 ..< n {
                    let etaA = etaB
                    etaB += dEta
                    found = (estimateError(degree, etaA, etaB) <= threshold)
                    if !found {
                        break
                    }
                }
            }
            n = n << 1
        }

        //     GeneralPath path = new GeneralPath(PathIterator.WIND_EVEN_ODD)
        var path = Path()

        let dEta = (eta2 - eta1) / Double(n)
        var etaB = eta1

        var cosEtaB = cos(etaB)
        var sinEtaB = sin(etaB)
        var aCosEtaB = a * cosEtaB
        var bSinEtaB = b * sinEtaB
        var aSinEtaB = a * sinEtaB
        var bCosEtaB = b * cosEtaB
        var xB = cx + aCosEtaB * cosTheta - bSinEtaB * sinTheta
        var yB = cy + aCosEtaB * sinTheta + bSinEtaB * cosTheta
        var xBDot = -aSinEtaB * cosTheta - bCosEtaB * sinTheta
        var yBDot = -aSinEtaB * sinTheta + bCosEtaB * cosTheta

        if isPieSlice {
            path.move(to: CGPoint(cx, cy))
            path.addLine(to: CGPoint(xB, yB))
        }
        else {
            path.move(to: CGPoint(xB, yB))
        }

        let t = tan(0.5 * dEta)
        let alpha = sin(dEta) * (sqrt(4 + 3 * t * t) - 1) / 3

        for _ in 0 ..< n {
            // let etaA  = etaB // Neverused
            let xA = xB
            let yA = yB
            let xADot = xBDot
            let yADot = yBDot

            etaB += dEta
            cosEtaB = cos(etaB)
            sinEtaB = sin(etaB)
            aCosEtaB = a * cosEtaB
            bSinEtaB = b * sinEtaB
            aSinEtaB = a * sinEtaB
            bCosEtaB = b * cosEtaB
            xB = cx + aCosEtaB * cosTheta - bSinEtaB * sinTheta
            yB = cy + aCosEtaB * sinTheta + bSinEtaB * cosTheta
            xBDot = -aSinEtaB * cosTheta - bCosEtaB * sinTheta
            yBDot = -aSinEtaB * sinTheta + bCosEtaB * cosTheta
            if degree == 1 {
                path.addLine(to: CGPoint(xB, yB))
            }
            else if degree == 2 {
                let k = (yBDot * (xB - xA) - xBDot * (yB - yA)) / (xADot * yBDot - yADot * xBDot)
                path.addQuadCurve(to: CGPoint(xB, yB), control: CGPoint(xA + k * xADot, yA + k * yADot))
            }
            else {
                path.addCurve(to: CGPoint(xB, yB), control1: CGPoint(xA + alpha * xADot, yA + alpha * yADot), control2: CGPoint(xB - alpha * xBDot, yB - alpha * yBDot))
            }
        }

        if isPieSlice {
            path.closeSubpath()
        }

        return path
    }

    //   /* Returns an iterator object that iterates along the Shape
    //    * boundary and provides access to the geometry of the Shape
    //    * outline.
    //    */
    //   public PathIterator getPathIterator(AffineTransform at) {
    //     return buildPathIterator(maxDegree, defaultFlatness, at)
    //   }

    //   /** Returns an iterator object that iterates along the Shape
    //    * boundary and provides access to a flattened view of the Shape
    //    * outline geometry.
    //    */
    //   public PathIterator getPathIterator(AffineTransform at, double flatness) {
    //     return buildPathIterator(1, flatness, at)
    //   }

    //   /** Tests if the interior of the Shape intersects the interior of a
    //    * specified rectangular area.
    //    */
    //   public boolean intersects(double x, double y, double w, double h) {
    //     double xPlusW = x + w
    //     double yPlusH = y + h
    //     return contains(x, y)
    //         || contains(xPlusW, y)
    //         || contains(x, yPlusH)
    //         || contains(xPlusW, yPlusH)
    //         || intersectOutline(x,      y,      xPlusW, y)
    //         || intersectOutline(xPlusW, y,      xPlusW, yPlusH)
    //         || intersectOutline(xPlusW, yPlusH, x,      yPlusH)
    //         || intersectOutline(x,      yPlusH, x,      y)
    //   }

    //   /** Tests if the interior of the Shape intersects the interior of a
    //    * specified Rectangle2D.
    //    */
    //   public boolean intersects(Rectangle2D r) {
    //     return intersects(r.getX(), r.getY(), r.getWidth(), r.getHeight())
    //   }
    //
}
