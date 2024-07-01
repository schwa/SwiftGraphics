import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct QuaternionEditor: View {
    @Binding
    var quaternion: simd_quatf

    init(_ quaternion: Binding<simd_quatf>) {
        self._quaternion = quaternion
    }

    public var body: some View {
        TextField("Real", value: $quaternion.real, format: .number)
        VectorEditor($quaternion.imag)
    }
}

#Preview {
    @Previewable @State var quaternion = simd_quatf()
    Form {
        QuaternionEditor($quaternion)
    }
}
