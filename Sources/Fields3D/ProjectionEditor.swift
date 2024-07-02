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

    public init(_ projection: Binding<Projection>) {
        type = projection.wrappedValue.meta
        _projection = projection
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
        case .matrix:
            //            let projection = Binding {
            //                projection
            //            } set: { newValue in
            //                self.projection = .matrix(newValue)
            //            }
            Text("UNIMPLEMENTED")
        case .perspective(let projection):
            let projection = Binding {
                projection
            } set: { newValue in
                self.projection = .perspective(newValue)
            }
            //                    let fieldOfView = Binding<SwiftUI.Angle>(get: { .degrees(projection.fovy) }, set: { projection.fovy = $0.radians })
            HStack {
                //                let binding = Binding<SwiftUI.Angle>(radians: projection.verticalAngleOfView.radians)
                //                TextField("FOVY", value: binding, format: .angle)
                // SliderPopoverButton(value: projection.fovy.degrees, in: 0...180, minimumValueLabel: { Image(systemName: "field.of.view.wide") }, maximumValueLabel: { Image(systemName: "field.of.view.ultrawide") })
            }
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
    }
}

#Preview {
    @Previewable @State var projection = Projection.perspective(.init())
    Form {
        ProjectionEditor($projection)
    }
}
