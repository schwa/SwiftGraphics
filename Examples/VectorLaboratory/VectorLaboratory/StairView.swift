import CoreGraphicsSupport
import SwiftUI
import VectorSupport

struct StairView: View {
    var body: some View {
        Canvas { context, _ in
            let rect = CGRect(x: 10, y: 10, width: 500, height: 100)
            context.stroke(Path(rect), with: .color(.red.opacity(0.5)))
            let points = [rect.minXMinY, rect.maxXMinY, rect.maxXMaxY, rect.minXMaxY]
            let d0 = CGPoint.distance(points[0], points[1])
            let d1 = CGPoint.distance(points[1], points[2])
            let longAxisPoints = d0 > d1 ? ((points[0], points[1]), (points[3], points[2])) : ((points[0], points[3]), (points[1], points[2]))
            let d = max(d0, d1)
            for n in stride(from: 0, through: d, by: 20) {
                let a = (longAxisPoints.0.1 - longAxisPoints.0.0) * (n / d) + longAxisPoints.0.0
                context.fill(Path(ellipseIn: CGRect(center: a, radius: 2)), with: .color(.red))
                let b = (longAxisPoints.1.1 - longAxisPoints.1.0) * (n / d) + longAxisPoints.1.0
                context.fill(Path(ellipseIn: CGRect(center: b, radius: 2)), with: .color(.red))
                context.stroke(Path(lineSegment: (a, b)), with: .color(.black))
            }
        }
    }
}
