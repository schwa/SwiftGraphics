import CoreGraphicsSupport
import SwiftUI

import Shapes2D

// import Algorithms
import simd

// https://pomax.github.io/bezierinfo/
// https://www.youtube.com/watch?v=aVwxzDHniEw
// https://www.youtube.com/watch?v=jvPPXbo87ds

struct BeziersView: View {
    @State
    var points: [CGPoint] = [[70, 250], [20, 110], [220, 60], [270, 200]]

    var body: some View {
        ZStack {
            LegacyPathEditor(points: $points)
            let curve = CubicBezierCurve(controlPoints: points)
            ZStack {
//                Path(curve: curve).stroke()
                Path(lines: curve.render()).stroke().foregroundColor(.red)
                Path.dots(curve.render(), radius: 2).fill().foregroundColor(.red)
            }
        }
    }
}
