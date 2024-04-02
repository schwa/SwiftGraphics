import SwiftUI
import CoreGraphicsSupport
import Algorithms
import VectorSupport

struct PathCanvas: View {
    
    @Binding
    var points: [CGPoint]
    
    @State
    var selection: Set<Int> = []
    
    let coordinateSpace = NamedCoordinateSpace.named("canvas")
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .gesture(SpatialTapGesture(coordinateSpace: coordinateSpace).onEnded({ value in
                    print(value.location)
                    points.append(value.location)
                }))
            
            let elements = points.windows(ofCount: 2).map(\.tuple).enumerated()
            ForEach(Array(elements), id: \.offset) { offset, points in
                let path = Path(lineSegment: points)
                path.stroke()
                    .foregroundStyle(Color.black)
                    .contentShape(Path(lineSegment: points, width: 20, lineCap: .round), eoFill: false)
                    .gesture(SpatialTapGesture(coordinateSpace: coordinateSpace).onEnded({ value in
                        self.points.insert(value.location, at: offset + 1)
                    }))
//                    .overlay {
//                        (Path(line: points, width: 20, lineCap: .round).stroke(Color.black.opacity(0.2)))
//                    }
                    .contextMenu {
                        Button("Split") {
                            let newPoint = (points.0 + points.1) / 2
                            self.points.insert(newPoint, at: offset + 1)
                        }
                        Button("Remove") {
                            self.points.remove(at: offset+1)
                            self.points.remove(at: offset)
                        }
                    }
                
            }
            ForEach(Array(points.enumerated()), id: \.0) { offset, point in
                Circle().position(point).frame(width: 8, height: 8)
                //.foregroundStyle(selection.contains(offset) ? Color.accentColor : .black)
                    .background {
                        if selection.contains(offset) {
                            RelativeTimelineView(schedule: .animation) { context, time in
                                Path.circle(center: point, radius: 10).fill(Color.accentColor)
                                    .colorEffect(ShaderLibrary.my_color_effect(.float(time)))
                            }
                        }
                    }
                    .contentShape(Path.circle(center: point, radius: 20))
                    .gesture(dragGesture(offset: offset))
                    .onTapGesture {
                        selection = Set([offset])
                    }
                    .contextMenu {
                        Button("Remove") {
                            self.points.remove(at: offset)
                        }
                    }
            }
        }
        .coordinateSpace(coordinateSpace)
        .inspector(isPresented: .constant(true)) {
            Table(points.identifiedByIndex(), selection: $selection) {
                TableColumn("X") { row in
                    let binding = Binding<Double>(get: { points[row.id].x }, set: { points[row.id].x = $0 })
                    TextField("X", value: binding, format: .number)
                }
                TableColumn("Y") { row in
                    let binding = Binding<Double>(get: { points[row.id].y }, set: { points[row.id].y = $0 })
                    TextField("Y", value: binding, format: .number)
                }
            }
        }
        .toolbar {
            Button("Import") {
                isFileImporterPresented = true
            }
            Button("Export") {
                isFileExporterPresented = true
            }
        }
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.json], onCompletion: { result in
            if case let .success(url) = result {
                let data = try! Data(contentsOf: url)
                self.points = try! JSONDecoder().decode([CGPoint].self, from: data)
            }
        })
        .fileExporter(isPresented: $isFileExporterPresented, item: JSONCodingTransferable(element: points)) { _ in }
    }
    
    @State
    var isFileImporterPresented = false
    @State
    var isFileExporterPresented = false
    
    func dragGesture(offset: Int) -> some Gesture {
        DragGesture(coordinateSpace: coordinateSpace).onChanged({ value in
            var location = value.location
            if NSEvent.modifierFlags.contains(.shift) {
                location = location.map { round($0 / 10) * 10 }
            }
            points[offset] = location
        })
    }
}
