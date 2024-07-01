import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct TransformEditor: View {
    @Binding
    var transform: Transform

    @State
    private var editedTransform: Transform

    @State
    private var mode: Transform.Storage.Base

    public init(_ transform: Binding<Transform>) {
        self._transform = transform
        self.editedTransform = transform.wrappedValue
        self.mode = transform.wrappedValue.storage.base
    }

    public var body: some View {
        Group {
            Picker("Mode", selection: $mode) {
                Text("Matrix").tag(Transform.Storage.Base.matrix)
                Text("SRT").tag(Transform.Storage.Base.srt)
            }
            switch editedTransform.storage {
            case .matrix:
                MatrixEditor($editedTransform.matrix)
            case .srt:
                SRTEditor($editedTransform.srt)
            }
        }
        .onChange(of: mode) {
            editedTransform = transform.converted(to: mode)
        }
        .onChange(of: transform) {
            editedTransform = transform.converted(to: mode)
        }
    }
}

extension Transform {
    func converted(to base: Transform.Storage.Base) -> Transform {
        switch base {
        case .matrix:
            Transform(matrix)
        case .srt:
            Transform(srt)
        }
    }
}
extension Transform.Storage {
    enum Base {
        case matrix
        case srt
    }

    var base: Base {
        switch self {
        case .matrix:
            .matrix
        case .srt:
            .srt
        }
    }
}

#Preview {
    @Previewable @State var transform = Transform()
    TransformEditor($transform)
}
