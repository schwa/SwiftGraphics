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
        //SketchEditorView(sketch: $sketch)
        LineDemoView()
    }
}

struct A: View {
//    var body: some View {
//        SketchCanvas()
//    }

    @State
    var points: [CGPoint] = [[50, 50], [250, 50], [300, 100]]

    var body: some View {
        ZStack {
            PathCanvas(points: $points)
            CustomStrokeView(points: points)
                .contentShape(.interaction, EmptyShape())
        }
    }
}
