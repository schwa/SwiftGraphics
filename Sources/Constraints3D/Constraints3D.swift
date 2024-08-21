import SwiftUI

extension ClosedRange where Bound == Angle {
    var degrees: ClosedRange<Double> {
        lowerBound.degrees ... upperBound.degrees
    }
}
