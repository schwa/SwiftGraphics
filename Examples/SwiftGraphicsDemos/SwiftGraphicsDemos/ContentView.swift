import SwiftGraphicsDemosSupport
import SwiftUI

struct ContentView: View {
    @Environment(\.openWindow)
    var openWindow

    var body: some View {
        SketchView()
            .toolbar {
                Button("Demos") {
                    openWindow(id: "demos")
                }
            }
    }
}
