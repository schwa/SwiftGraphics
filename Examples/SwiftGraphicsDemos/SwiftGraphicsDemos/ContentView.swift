import Algorithms
import CoreGraphicsSupport
import Observation
import Sketches
import SwiftUI
import Shapes2D

struct ContentView: View {

    @Environment(\.openWindow)
    var openWindow

    @State
    var sketch = Sketch()

    var body: some View {
        SketchView()
            .toolbar {
                Button("Demos") {
                    openWindow(id: "demos")
                }
            }
    }
}


