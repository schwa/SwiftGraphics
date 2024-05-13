import Algorithms
import CoreGraphicsSupport
import Observation
import Shapes2D
import Sketches
import SwiftUI

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
