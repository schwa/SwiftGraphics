import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

#Preview {
    @Previewable @State var matrix = simd_float4x4()
    @Previewable @State var projection = Projection.perspective(.init())
    Form {
        MatrixEditor($matrix)
        ProjectionEditor($projection)
    }
}
