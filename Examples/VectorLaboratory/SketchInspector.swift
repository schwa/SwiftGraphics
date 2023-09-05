import SwiftUI
import CoreGraphicsSupport
import Algorithms
import Observation
import VectorSupport
//import Everything
import SwiftFormats
import Sketches

struct ElementsInspectorView: View {

    @Binding
    var sketch: Sketch
    
    @Binding
    var selection: Set<Element.ID>

    var body: some View {
        if selection.isEmpty {
            ContentUnavailableView {
                Text("No selection")
            }
        }
        else if selection.count > 1 {
            ContentUnavailableView {
                Text("Multiple selection")
            }
        }
        else {
            let index = sketch.elements.firstIndex(where: { $0.id == selection.first! })!
            let binding = Binding {
                sketch.elements[index]
            } set: { newValue in
                sketch.elements[index] = newValue
            }
            ElementDetailView(element: binding)
        }
    }
}

struct ElementDetailView: View {
    @Binding
    var element: Element
    
    var body: some View {
        Form {
            LabeledContent("ID", value: "\(element.id)")
            ColorPicker(selection: $element.color, supportsOpacity: true, label: { Text("Color") })
            TextField("Label", text: $element.label)
            //TextField("Position", value: $element.position, format: .point)
        }
    }
}
