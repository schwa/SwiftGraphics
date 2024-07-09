import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct ProjectionEditor: View {
    @State
    private var type: Projection.Meta

    @Binding
    var projection: Projection

    var drawableSize: SIMD2<Float>?

    public init(_ projection: Binding<Projection>, drawableSize: SIMD2<Float>? = nil) {
        type = projection.wrappedValue.meta
        _projection = projection
        self.drawableSize = drawableSize
    }

    public var body: some View {
        Picker("Type", selection: $type) {
            ForEach(Projection.Meta.allCases, id: \.self) { type in
                Text("\(type)").tag(type)
            }
        }
        .labelsHidden()
        .onChange(of: type) {
            guard type != projection.meta else {
                return
            }
            switch type {
            case .matrix:
                projection = .matrix(.identity)
            case .perspective:
                projection = .perspective(.init())
            case .orthographic:
                projection = .orthographic(.init(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1))
            }
        }
        switch projection {
        case .matrix(let projection):
            let projection = Binding {
                projection
            } set: { newValue in
                self.projection = .matrix(newValue)
            }
            MatrixEditor(projection)
        case .perspective(let projection):
            let projection = Binding {
                projection
            } set: { newValue in
                self.projection = .perspective(newValue)
            }
            TextField("Angle of View (Vertical)", value: projection.verticalAngleOfView, format: .angle)
            TextField("Clipping Distance", value: projection.zClip, format: ClosedRangeFormatStyle(substyle: .number))
        case .orthographic(let projection):
            let projection = Binding {
                projection
            } set: { newValue in
                self.projection = .orthographic(newValue)
            }
            TextField("Left", value: projection.left, format: .number)
            TextField("Right", value: projection.right, format: .number)
            TextField("Bottom", value: projection.bottom, format: .number)
            TextField("Top", value: projection.top, format: .number)
            TextField("Near", value: projection.near, format: .number)
            TextField("Far", value: projection.far, format: .number)
        }
        if let drawableSize {
            let matrix = projection.projectionMatrix(for: drawableSize)
            MatrixView(matrix)
        }
    }
}

#Preview {
    @Previewable @State var projection = Projection.perspective(.init())
    Form {
        ProjectionEditor($projection)
    }
}
