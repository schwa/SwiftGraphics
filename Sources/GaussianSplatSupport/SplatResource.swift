import Constraints3D
import Foundation
import simd
import SwiftUI

public struct SplatResource {
    public var name: String
    public var url: URL
    public var bounds: ConeBounds

    public init(name: String, url: URL, bounds: ConeBounds) {
        self.name = name
        self.url = url
        self.bounds = bounds
    }
}
