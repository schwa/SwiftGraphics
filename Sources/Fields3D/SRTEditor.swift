import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct SRTEditor: View {
    @Binding
    var srt: SRT

    public init(_ srt: Binding<SRT>) {
        self._srt = srt
    }

    public var body: some View {
        Section("Scale") {
            VectorEditor($srt.scale)
        }
        Section("Rotation") {
            RotationEditor($srt.rotation)
        }
        Section("Translation") {
            VectorEditor($srt.translation)
        }
    }
}

#Preview {
    @Previewable @State var srt = SRT()
    SRTEditor($srt)
}
