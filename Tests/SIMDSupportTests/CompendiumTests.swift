import simd
@testable import SIMDSupport
import XCTest
import SwiftUI

// https://gpuopen.com/learn/matrix-compendium/matrix-compendium-intro

final class CompendiumTests: XCTestCase {
    func test() {
        switch (q1(), q2(), q3()) {
        case ("1a", "2a", "3a"): print("Pre-multiplication, Row-Major, Right-handed")
        case ("1b", "2a", "3a"): print("Pre-multiplication, Column-Major, Left-handed")
        case ("1a", "2b", "3a"): print("Pre-multiplication, Row-Major, Left-handed")
        case ("1b", "2b", "3a"): print("Pre-multiplication, Column-Major, Right-handed")
        case ("1a", "2a", "3b"): print("Post-multiplication, Column-Major, Left-handed")
        case ("1b", "2a", "3b"): print("Post-multiplication, Row-Major, Right-handed")
        case ("1a", "2b", "3b"): print("Post-multiplication, Column-Major, Right-handed") // ***
        case ("1b", "2b", "3b"): print("Post-multiplication, Row-Major, Left-handed")
        default:
            fatalError()
        }
    }

    func q1() -> String {
        // 1. How is the translation matrix is constructed? It is necessary to check how the components of the translation vector XYZ are stored in memory. Are they stored next to each other (1a) or are they away from each other (1b)?
        let translation = simd_float4x4(translate: [10.0, 20.0, 30.0])
        let i1 = translation.scalars.firstIndex(of: 10.0)!
        let i2 = translation.scalars.firstIndex(of: 20.0)!
        let i3 = translation.scalars.firstIndex(of: 30.0)!
        if i3 == i2 + 1 && i2 == i1 + 1 {
            return "1a"
        }
        else {
            return "1b"
        }
    }

    func q2() -> String {
        // 2. It is necessary to inspect how rotation around X-Axis or Z-Axis is stored in memory. Is the first in memory stored −sin element (2a) or sin (2b), or in case of rotation around Y-Axis the first in memory is stored sin element (2a) or −sin (2b)?

        let angle = Angle.degrees(45)

        let xRotation = simd_float4x4(rotationAngle: angle, axis: [1, 0, 0])
        let xResult = xRotation.scalars.first(where: { $0 != 0 && $0 != 1 })!

        let yRotation = simd_float4x4(rotationAngle: angle, axis: [0, 1, 0])
        let yResult = yRotation.scalars.first(where: { $0 != 0 && $0 != 1 })!

        let zRotation = simd_float4x4(rotationAngle: angle, axis: [0, 0, 1])
        let zResult = zRotation.scalars.first(where: { $0 != 0 && $0 != 1 })!

        if xResult < 0 {
            assert(yResult < 0)
            assert(zResult < 0)
            return "2a"
        }
        else {
            return "2b"
        }
    }

    func q3() -> String {
        // Determination of the order in which the transformations (Scale, Rotation, and Translation) are composed. Whether it is executed in the order S * R * T (3a) or T * R * S (3b)? Or if Matrix Vector multiplication is computed in order M * V (3a) or V * M (3b)?
        "3b"
    }
}
