import Foundation
import simd
import SIMDSupport
import SwiftUI

/// A representation of a camera.
@available(*, deprecated, message: "Deprecated")
public struct PerspectiveCamera: Hashable, Sendable {
    /// The vertical angle of view of the camera (sometimes called "fovY")
    public var angleOfView: Angle

    /// The z range of the camera. The camera will not render anything outside of this range. Generally 0.1 ... 100 is a good range.
    public var zRange: ClosedRange<Double>

    /// Create a camera
    public init(angleOfView: Angle = Angle(degrees: 90), zRange: ClosedRange<Double> = 0.1 ... 1_000) {
        self.angleOfView = angleOfView
        self.zRange = zRange
    }
}

public extension PerspectiveCamera {
    func projectionMatrix(aspectRatio: Float) -> simd_float4x4 {
        simd_float4x4.perspective(aspect: aspectRatio, fovy: Float(angleOfView.radians), near: Float(zRange.lowerBound), far: Float(zRange.upperBound))
    }

    func horizontalAngleOfView(aspectRatio: Double) -> Angle {
        let fovy = angleOfView.radians
        let fovx = 2 * atan(tan(fovy / 2) * aspectRatio)
        return Angle(radians: fovx)
    }
}

extension PerspectiveCamera: CustomStringConvertible {
    public var description: String {
        "PerspectiveCamera(angleOfView: \(angleOfView.degrees.formatted())°, zRange: \(zRange.lowerBound.formatted()) ... \(zRange.upperBound.formatted()))"
    }
}

public extension PerspectiveCamera {
    func offset(for angle: Angle, cameraYaw: Angle, in size: CGSize) -> CGSize {
        let aspectRatio = size.width / size.height
        let relativeAngle = ((angle - cameraYaw) + .degrees(180)).truncatingRemainder(dividingBy: .degrees(360)) - .degrees(180)
        let horizontalAngleOfView = horizontalAngleOfView(aspectRatio: aspectRatio)
        let x = relativeAngle.radians / horizontalAngleOfView.radians * size.width
        return .init(width: x, height: 0)
    }
}
