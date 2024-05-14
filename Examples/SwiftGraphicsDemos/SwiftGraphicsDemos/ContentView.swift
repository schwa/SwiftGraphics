import SwiftUI
import SwiftGraphicsDemosSupport

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
