import Algorithms
import CoreGraphicsSupport
import Observation
import Sketches
import SwiftUI
import Shapes2D

struct ContentView: View {
    @State
    var sketch = Sketch()

    var body: some View {
//        LineDemoView()
//        CustomStrokeEditor()

//        PathEditorDemo()
BeziersView()
    }
}

