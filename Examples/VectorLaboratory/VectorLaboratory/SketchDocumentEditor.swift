import Sketches
import SwiftUI

struct SketchDocumentEditor: View {
    @Binding
    var document: SketchDocument

    var fileURL: URL?

    var body: some View {
        SketchEditorView(sketch: $document.sketch)
            .sketchOverlay {
                ZStack {
                    LineExperimentView(sketch: $document.sketch)
                    MarkingsView()
                }
                .contentShape(EmptyShape())
            }
    }
}
