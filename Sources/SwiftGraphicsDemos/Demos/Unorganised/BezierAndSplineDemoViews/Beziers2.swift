import BaseSupport
import CoreGraphics
import Foundation
import SwiftGraphicsSupport

// swiftlint:disable identifier_name

//// Representation of a quadratic BÃ©zier curve. p0 is the start point, p1 is the control point, p2 is the end point.
// let quadBezControlPoints = {
//  p0: { x: 10, y: 10 },
//  p1: { x: 50, y: 90 },
//  p2: { x: 90, y: 10 },
// };

// https://minus-ze.ro/posts/flattening-bezier-curves-and-arcs/

// The integral functions that compute how many segments are needed for flattening and all the t values at each subdivision point.
// They are explained here: https://raphlinus.github.io/graphics/curves/2019/12/23/flatten-quadbez.html
func approxIntegral(_ x: Double) -> Double {
    let d = 0.67
    return x / (1 - d + pow(pow(d, 4) + 0.25 * x * x, 0.25))
}

func approxInvIntegral(_ x: Double) -> Double {
    let b = 0.39
    return x * (1 - b + sqrt(b * b + 0.25 * x * x))
}

struct QuadraticBezierCurve {
    var p0: CGPoint
    var p1: CGPoint
    var p2: CGPoint
}

// Evaluating a quadratic curve q at the point t. Returns the (x, y) coordinate at that point.
func evalQuadBez(_ q: QuadraticBezierCurve, _ t: Double) -> CGPoint {
    let mt = 1 - t
    let x = q.p0.x * mt * mt + 2 * q.p1.x * t * mt + q.p2.x * t * t
    let y = q.p0.y * mt * mt + 2 * q.p1.y * t * mt + q.p2.y * t * t
    return .init(x: x, y: y)
}

struct MySegment {
    var x0: Double
    var x2: Double
    var scale: Double
    var cross: Double
}

//// Mapping the quadratic curve q to a segment of the x^2 parabola. Also explained in the blog post.
func quadBezMapToBasic(_ q: QuadraticBezierCurve) -> MySegment {
    let ddx = 2 * q.p1.x - q.p0.x - q.p2.x
    let ddy = 2 * q.p1.y - q.p0.y - q.p2.y
    let u0 = (q.p1.x - q.p0.x) * ddx + (q.p1.y - q.p0.y) * ddy
    let u2 = (q.p2.x - q.p1.x) * ddx + (q.p2.y - q.p1.y) * ddy
    let cross = (q.p2.x - q.p0.x) * ddy - (q.p2.y - q.p0.y) * ddx
    let x0 = u0 / cross
    let x2 = u2 / cross
    let scale = abs(cross) / (hypot(ddx, ddy) * abs(x2 - x0))
    return .init(
        x0: x0,
        x2: x2,
        scale: scale,
        cross: cross
    )
}

// This is the function that actually converts the curve to a sequence of lines. More precisely, it returns an array
// of t values, which you can then evaluate and get the actual line coordinates:
//
//     let q = { p0: { x: 10, y: 10 }, p1: { x: 50, y: 90 }, p2: { x: 90, y: 10 } };
//     let ts = quadBezFlatten(q);
//     for (let t of ts) {
//         const { x, y } = evalQuadBez(q, t);
//         // Now you can draw line between each of these points and you will render your curve.
//     }
func quadBezFlatten(_ q: QuadraticBezierCurve, tolerance: Double) -> [CGPoint] {
    let params = quadBezMapToBasic(q)
    let a0 = approxIntegral(params.x0)
    let a2 = approxIntegral(params.x2)
    let count = 0.5 * Swift.abs(a2 - a0) * sqrt(params.scale / tolerance)
    let n = ceil(count)
    // Handle case where all the points are collinear and the end point is between the start point and the control point
    if !n.isFinite || n == 0 || n == 1 {
        // Find t values where the derivative is 0
        let divx = q.p0.x + q.p2.x - 2 * q.p1.x
        let divy = q.p0.y + q.p2.y - 2 * q.p1.y
        let tx = (q.p0.x - q.p1.x) / divx
        let ty = (q.p0.y - q.p1.y) / divy
        var ts: [Double] = []
        if tx.isFinite && tx > 0 && tx < 1 {
            ts.append(tx)
        }
        if ty.isFinite && ty > 0 && ty < 1 {
            if ty > ts[ts.count - 1] {
                ts.append(ty)
            }
        }
        ts.append(1.0)
        //        quadBezState.numberOfSegments = ts.length;
        //        return ts;
        unimplemented()
    }
    let u0 = approxInvIntegral(a0)
    let u2 = approxInvIntegral(a2)
    var result: [Double] = []
    for i in stride(from: 1, to: n, by: 1) {
        let u = approxInvIntegral(a0 + ((a2 - a0) * i) / n)
        let t = (u - u0) / (u2 - u0)
        result.append(t)
    }
    result.append(1)
    return result.adjacentPairs().map { CGPoint($0.0, $0.1) }
}

////
////// This is the curve used for the blossoming example. It's a cubic BÃ©zier curve.
//// const blossomControlPoints = {
////  p0: { x: 5, y: 95 },
////  p1: { x: 5, y: 5 },
////  p2: { x: 95, y: 5 },
////  p3: { x: 95, y: 95 },
//// };
////
////// Linear interpolation at t between two points. Will come in very handy for blossoming.
//// function lerp(v0, v1, t) {
////  return (1 - t) * v0 + t * v1;
//// }
////
////// Get the (x, y) point at t for the line [p0, p1].
//// function lineAt(p0, p1, t) {
////  return { x: lerp(p0.x, p1.x, t), y: lerp(p0.y, p1.y, t) };
//// }
////
////// Returns the three cubic curves split between t0 and t1 for the curve c:
//// function blossom(c, t0, t1) {
////  const { p0, p1, p2, p3 } = c;
////
////  // Two De Casteljau subdivision simultaneously. After we have the two expansions, we can use the intermediate
////  // lines of both subdivisions to compute the control points for our middle curve.
////  // This can be achieved intuitively by computing the point at the t value for the other curve.
////  // For the first curve, we want to compute the point at t1 on the line where t0 is.
////  // For the last curve, we want to compute the point at t0 on the line where t1 is.
////  // These two points will be our control points for the cubic in the middle.
////
////  // Starting cubic (from 0.0 to t0):
////  const p01a = lineAt(p0, p1, t0);
////  const p12a = lineAt(p1, p2, t0);
////  const p23a = lineAt(p2, p3, t0);
////
////  const p0aa = lineAt(p01a, p12a, t0);
////  const p1aa = lineAt(p12a, p23a, t0);
////
////  const paaa = lineAt(p0aa, p1aa, t0);
////
////  const starting = { p0: p0, p1: p01a, p2: p0aa, p3: paaa };
////
////  // Ending cubic (from t1 to 1.0):
////  const p01b = lineAt(p0, p1, t1);
////  const p12b = lineAt(p1, p2, t1);
////  const p23b = lineAt(p2, p3, t1);
////
////  const p0bb = lineAt(p01b, p12b, t1);
////  const p1bb = lineAt(p12b, p23b, t1);
////
////  const pbbb = lineAt(p0bb, p1bb, t1);
////
////  const ending = { p0: pbbb, p1: p1bb, p2: p23b, p3: p3 };
////
////  // The middle cubic (from t0 to t1):
////  const paab = lineAt(p0aa, p1aa, t1);
////  const pabb = lineAt(p0bb, p1bb, t0);
////
////  const middle = { p0: paaa, p1: paab, p2: pabb, p3: pbbb };
////
////  return {
////    starting: starting,
////    middle: middle,
////    ending: ending,
////  };
//// }
////
////// Representation of the cubic BÃ©zier curve. p0 is the start point, p1 and p2 are the control points, p3 is the end point.
//// let cubicBezControlPoints = {
////  p0: { x: 5, y: 95 },
////  p1: { x: 35, y: 5 },
////  p2: { x: 65, y: 95 },
////  p3: { x: 95, y: 5 },
//// };
////
////// Evaluating the cubic curve c at parameter t. Returns the (x, y) coordinate at that point.
//// function evalCubicBez(c, t) {
////  const t2 = t * t;
////  const t3 = t2 * t;
////  const mt = 1.0 - t;
////  const mt2 = mt * mt;
////  const mt3 = mt2 * mt;
////
////  const x =
////    c.p0.x * mt3 + c.p1.x * 3 * mt2 * t + c.p2.x * 3 * mt * t2 + c.p3.x * t3;
////  const y =
////    c.p0.y * mt3 + c.p1.y * 3 * mt2 * t + c.p2.y * 3 * mt * t2 + c.p3.y * t3;
////
////  return { x: x, y: y };
//// }
////
////// Effectively gives the same result as blossom(c).middle, but is easier to implement.
////// Stole it from lyon2d_geom: https://github.com/nical/lyon/blob/2407b7f5e326b2a8f66bfae81fe02d850d8b0acc/crates/geom/src/cubic_bezier.rs#L153
//// function cubicBezSplitRange(c, t0, t1) {
////  const from = evalCubicBez(c, t0);
////  const to = evalCubicBez(c, t1);
////  const dxFrom = c.p1.x - c.p0.x;
////  const dyFrom = c.p1.y - c.p0.y;
////  const dxCtrl = c.p2.x - c.p1.x;
////  const dyCtrl = c.p2.y - c.p1.y;
////  const dxTo = c.p3.x - c.p2.x;
////  const dyTo = c.p3.y - c.p2.y;
////  const d = {
////    p0: { x: dxFrom, y: dyFrom },
////    p1: { x: dxCtrl, y: dyCtrl },
////    p2: { x: dxTo, y: dyTo },
////  };
////  const dt = t1 - t0;
////  const xCtrl1 = from.x + evalQuadBez(d, t0).x * dt;
////  const yCtrl1 = from.y + evalQuadBez(d, t0).y * dt;
////  const xCtrl2 = to.x - evalQuadBez(d, t1).x * dt;
////  const yCtrl2 = to.y - evalQuadBez(d, t1).y * dt;
////
////  return {
////    p0: from,
////    p1: { x: xCtrl1, y: yCtrl1 },
////    p2: { x: xCtrl2, y: yCtrl2 },
////    p3: to,
////  };
//// }
////
////// Approximate a cubic to a single quadratic
////// Works by getting the intersection between the lines [p0, p1] and [p3, p2], and using that as the control point for the
////// resulting quadratic. Terrible as a general approximation, but great when the cubic is sufficiently close to a quadratic.
////// We only call this in the subdivision steps so that is okay.
//// function cubicBezToQuadratic(c) {
////  const c1x = (c.p1.x * 3 - c.p0.x) * 0.5;
////  const c1y = (c.p1.y * 3 - c.p0.y) * 0.5;
////  const c2x = (c.p2.x * 3 - c.p3.x) * 0.5;
////  const c2y = (c.p2.y * 3 - c.p3.y) * 0.5;
////  const cx = (c1x + c2x) * 0.5;
////  const cy = (c1y + c2y) * 0.5;
////
////  return {
////    p0: c.p0,
////    p1: { x: cx, y: cy },
////    p2: c.p3,
////  };
//// }
////
////// Returns the number of quadratics needed to approximate the cubic c, given the specified tolerance.
//// function cubicBezNumQuadratics(c, tolerance) {
////  const x = c.p0.x - 3 * c.p1.x + 3 * c.p2.x - c.p3.x;
////  const y = c.p0.y - 3 * c.p1.y + 3 * c.p2.y - c.p3.y;
////  const err = x * x + y * y;
////
////  let result = err / (432.0 * tolerance * tolerance);
////  return Math.max(Math.ceil(Math.pow(result, 1.0 / 6.0)), 1.0);
//// }
////
////// Converting the cubic c to a sequence of quadratics, with the specified tolerance.
////// Returns an array that contains these quadratics.
//// function cubicBezToQuadratics(c, tolerance) {
////  const numQuads = cubicBezNumQuadratics(c, tolerance);
////  const step = 1.0 / numQuads;
////  const n = Math.trunc(numQuads);
////  let t0 = 0.0;
////
////  let result = [];
////  for (let i = 0; i < n - 1; ++i) {
////    const t1 = t0 + step;
////    const quad = cubicBezSplitRange(c, t0, t1);
////    result.push(cubicBezToQuadratic(quad));
////    t0 = t1;
////  }
////
////  const quad = cubicBezSplitRange(c, t0, 1.0);
////  result.push(cubicBezToQuadratic(quad));
////
////  return result;
//// }
////
////// Representation of the elliptical arc, just like in the SVG notation: https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Paths#arcs
//// let arcControlPoints = {
////  p0: { x: 20, y: 50 },
////  p1: { x: 80, y: 50 },
////  radius: { x: 50, y: 100 },
////  theta: 0,
////  largeArc: 0,
////  sweep: 0,
//// };
////
////// Converts the angle given by the user to radians.
//// function toRadians(angle) {
////  return (angle * 2 * Math.PI) / 360;
//// }
////
////// Returns the angle between u and v, where u and v are unit vectors.
//// function unitVectorAngle(u, v) {
////  const sign = u.x * v.y - u.y * v.x < 0 ? -1 : 1;
////  const dot = u.x * v.x + u.y * v.y;
////  const dotClamped = Math.min(Math.max(dot, -1.0), 1.0);
////
////  return sign * Math.acos(dotClamped);
//// }
////
////// Converts the arc notation to the center parametrization.
////// With this, we now have a center (cx, cy), a theta and a deltaTheta which tell us exactly where to start drawing the ellipse,
////// and where to stop. We start at theta, and stop at theta + deltaTheta.
//// function arcCenterParametrization(
////  p1,
////  p2,
////  largeArc,
////  sweep,
////  radius,
////  sinTheta,
////  cosTheta
//// ) {
////  const x1p = (cosTheta * (p1.x - p2.x)) / 2 + (sinTheta * (p1.y - p2.y)) / 2;
////  const y1p = (-sinTheta * (p1.x - p2.x)) / 2 + (cosTheta * (p1.y - p2.y)) / 2;
////
////  const rxSq = radius.x * radius.x;
////  const rySq = radius.y * radius.y;
////  const x1pSq = x1p * x1p;
////  const y1pSq = y1p * y1p;
////
////  let radicant = Math.max(rxSq * rySq - rxSq * y1pSq - rySq * x1pSq, 0);
////  radicant /= rxSq * y1pSq + rySq * x1pSq;
////  radicant = Math.sqrt(radicant) * (largeArc === sweep ? -1 : 1);
////
////  const cxp = ((radicant * radius.x) / radius.y) * y1p;
////  const cyp = radicant * (-radius.y / radius.x) * x1p;
////
////  const cx = cosTheta * cxp - sinTheta * cyp + (p1.x + p2.x) / 2;
////  const cy = sinTheta * cxp + cosTheta * cyp + (p1.y + p2.y) / 2;
////
////  const v1x = (x1p - cxp) / radius.x;
////  const v1y = (y1p - cyp) / radius.y;
////  const v2x = (-x1p - cxp) / radius.x;
////  const v2y = (-y1p - cyp) / radius.y;
////
////  const theta1 = unitVectorAngle({ x: 1, y: 0 }, { x: v1x, y: v1y });
////  let deltaTheta = unitVectorAngle({ x: v1x, y: v1y }, { x: v2x, y: v2y });
////
////  if (sweep === 0 && deltaTheta > 0) {
////    deltaTheta -= 2 * Math.PI;
////  }
////  if (sweep === 1 && deltaTheta < 0) {
////    deltaTheta += 2 * Math.PI;
////  }
////
////  return {
////    center: { x: cx, y: cy },
////    theta: theta1,
////    deltaTheta: deltaTheta,
////  };
//// }
////
////// Approximates a circular arc on the unit circle between theta and deltaTheta.
//// function approximateUnitArc(theta, deltaTheta) {
////  const alpha = (4 / 3) * Math.tan(deltaTheta / 4);
////
////  let x1 = Math.cos(theta);
////  let y1 = Math.sin(theta);
////  let x2 = Math.cos(theta + deltaTheta);
////  let y2 = Math.sin(theta + deltaTheta);
////
////  return {
////    p0: { x: x1, y: y1 },
////    p1: { x: x1 - y1 * alpha, y: y1 + x1 * alpha },
////    p2: { x: x2 + y2 * alpha, y: y2 - x2 * alpha },
////    p3: { x: x2, y: y2 },
////  };
//// }
////
////// After we have the approximation for an arc on the unit circle, we use this function to scale it back to the original ellipse.
//// function applyArcPointTransform(p, centerP, radius, sinTheta, cosTheta) {
////  let x = p.x;
////  let y = p.y;
////
////  x *= radius.x;
////  y *= radius.y;
////
////  const xp = cosTheta * x - sinTheta * y;
////  const yp = sinTheta * x + cosTheta * y;
////
////  return { x: xp + centerP.center.x, y: yp + centerP.center.y };
//// }
////
////// Converts the elliptical arc to a sequence of cubic BÃ©zier curves. Returns an array with these cubics.
////// It won't try to approximate arcs longer that pi/4 with a single cubic, for great quality output.
//// function arcToCubicBez(p1, p2, largeArc, sweep, radius, theta) {
////  const sinTheta = Math.sin(toRadians(theta));
////  const cosTheta = Math.cos(toRadians(theta));
////
////  const x1p = (cosTheta * (p1.x - p2.x)) / 2 + (sinTheta * (p1.y - p2.y)) / 2;
////  const y1p = (-sinTheta * (p1.x - p2.x)) / 2 + (cosTheta * (p1.y - p2.y)) / 2;
////
////  if (x1p === 0 && y1p === 0) {
////    return [];
////  }
////  if (radius.x === 0 || radius.y === 0) {
////    return [];
////  }
////
////  let rx = Math.abs(radius.x);
////  let ry = Math.abs(radius.y);
////
////  const lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
////
////  if (lambda > 1) {
////    rx *= Math.sqrt(lambda);
////    ry *= Math.sqrt(lambda);
////  }
////
////  const centerP = arcCenterParametrization(
////    p1,
////    p2,
////    largeArc,
////    sweep,
////    { x: rx, y: ry },
////    sinTheta,
////    cosTheta
////  );
////
////  let result = [];
////  theta = centerP.theta;
////  let deltaTheta = centerP.deltaTheta;
////
////  const numSegments = Math.max(
////    Math.ceil(Math.abs(deltaTheta) / (Math.PI / 2)),
////    1
////  );
////  deltaTheta /= numSegments;
////
////  for (let i = 0; i < numSegments; ++i) {
////    const curve = approximateUnitArc(theta, deltaTheta);
////
////    result.push({
////      p0: applyArcPointTransform(
////        curve.p0,
////        centerP,
////        { x: rx, y: ry },
////        sinTheta,
////        cosTheta
////      ),
////      p1: applyArcPointTransform(
////        curve.p1,
////        centerP,
////        { x: rx, y: ry },
////        sinTheta,
////        cosTheta
////      ),
////      p2: applyArcPointTransform(
////        curve.p2,
////        centerP,
////        { x: rx, y: ry },
////        sinTheta,
////        cosTheta
////      ),
////      p3: applyArcPointTransform(
////        curve.p3,
////        centerP,
////        { x: rx, y: ry },
////        sinTheta,
////        cosTheta
////      ),
////    });
////
////    theta += deltaTheta;
////  }
////
////  return result;
//// }
