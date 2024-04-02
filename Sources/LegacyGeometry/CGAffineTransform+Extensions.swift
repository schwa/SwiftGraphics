import CoreGraphics
import CoreGraphicsSupport

public extension CGAffineTransform {
    // Constructor with two fingers' positions while moving fingers.
    init(from1: CGPoint, from2: CGPoint, to1: CGPoint, to2: CGPoint) {
        if from1 == from2 || to1 == to2 {
            self = CGAffineTransform.identity
        }
        else {
            let scale = to2.distance(to: to1) / from2.distance(to: from1)
            let angle1 = (to2 - to1).angle, angle2 = (from2 - from1).angle
            self = CGAffineTransform(translation: to1 - from1)
                * CGAffineTransform(scale: scale, origin: to1)
                * CGAffineTransform(rotation: angle1 - angle2, origin: to1)
        }
    }
}
