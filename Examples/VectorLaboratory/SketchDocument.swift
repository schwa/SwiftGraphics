import SwiftUI
import UniformTypeIdentifiers
import Sketches

extension UTType {
    static let sketchDocument = UTType(exportedAs: "io.schwa.sketch-document", conformingTo: .json)
}

struct SketchDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.sketchDocument, .json]
    
    var sketch: Sketch
    
    init() {
        sketch = Sketch()
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            fatalError()
        }
        sketch = try JSONDecoder().decode(Sketch.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(sketch)
        return FileWrapper(regularFileWithContents: data)
    }
}


