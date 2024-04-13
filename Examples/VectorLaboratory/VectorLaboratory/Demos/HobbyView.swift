import Foundation
import SwiftUI

struct HobbyView: View {
    @State
    var points: [CGPoint] = [[70,250], [20, 110], [220, 60], [270, 200]]

    var body: some View {
        ZStack {
            LegacyPathEditor(points: $points)
                .foregroundColor(.gray)
            let points = hobby(points: points, omega: 0)
            ZStack {
//                Path(curve: curve).stroke()
                Path(lines: points).stroke()
            }
        }
    }
}
