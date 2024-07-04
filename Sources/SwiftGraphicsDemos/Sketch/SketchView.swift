import BaseSupport
import Observation
import Shapes2D
import SwiftFormats
import SwiftUI
import SwiftUISupport
import BaseSupport

@Observable
class SketchModel {
    //    @ObservationIgnored
    //    @CodableAppStorage("SHAPES")
    var shapes: [Identified<UUID, MyShape>] = []

    var selection: Set<UUID> = []

    var currentTool: Tool = .select

    var editedShape: MyShape?
}

extension NamedCoordinateSpace {
    nonisolated(unsafe) static let canvas = NamedCoordinateSpace.named("CANVAS")
}

public struct SketchDemoView: View, DemoView {
    public init() {
    }

    public var body: some View {
        SketchView()
    }
}

public struct SketchView: View {
    @State
    private var model = SketchModel()

    @Environment(\.undoManager)
    var undoManager

    let function = ShaderLibrary.my_color_effect_2

    public init() {
    }

    public var body: some View {
        VStack {
            ZStack {
                Color.white
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        Canvas { context, _ in
                            for shape in model.shapes {
                                let path = Path(shape.content)
                                //                                if model.selection.contains(shape.id) {
                                //                                    context.stroke(path, with: .color(.accentColor), style: .init(lineWidth: 8))
                                //                                }
                                context.stroke(path, with: .color(.black))
                            }
                        }
                        if !model.selection.isEmpty {
                            RelativeTimelineView(schedule: .animation) { _, time in
                                let shader = function(.color(.blue), .color(.green), .float(time))
                                ForEach(Array(model.selection), id: \.self) { id in
                                    if let shape = model.shapes.first(identifiedBy: id)?.content {
                                        ZStack {
                                            Path(shape).stroke(shader, lineWidth: 5)
                                            Path(shape).stroke(.black)
                                        }
                                    }
                                }
                            }
                            .allowsHitTesting(false)
                        }
                    }
                    .coordinateSpace(.canvas)
                    .frame(width: 4_096, height: 4_096)
                    .modifier(currentToolModifier)
                }
            }
            if model.editedShape != nil {
                ShapeEditor(shape: $model.editedShape.unsafeBinding())
                    .padding()
            }
        }
        .toolbarRole(.editor)
        .toolbar(id: "main") {
            ToolbarItem(id: "Group", placement: .principal) {
                Picker("Tool", selection: $model.currentTool) {
                    Label("Select", systemImage: "lasso").tag(Tool.select)
                    Label("Line", systemImage: "line.diagonal").tag(Tool.line)
                    Label("Circle (center point)", systemImage: "circle").tag(Tool.circle)
                    //                    Label("Circle (3 point)", systemImage: "gear").tag("Circle (3 point)")
                    //                    Label("Ellipse", systemImage: "gear").tag("Ellipse")
                    //                    Label("Arc (3 point)", systemImage: "gear").tag("Arc (3 point)")
                    //                    Label("Arc (Tangent)", systemImage: "gear").tag("Arc (Tangent)")
                    //                    Label("Arc (Center point)", systemImage: "gear").tag("Arc (Center point)")
                    //                    Label("Arc (Elliptical)", systemImage: "gear").tag("Arc (Elliptical)")
                    //                    Label("Arc (Conic)", systemImage: "gear").tag("Arc (Conic)")
                    //                    Label("Inscribed polygon", systemImage: "gear").tag("Inscribed polygon")
                    //                    Label("Circumscribed polygon", systemImage: "gear").tag("Circumscribed polygon")
                    //                    Label("Spline", systemImage: "gear").tag("Spline")
                    //                    Label("Bezier", systemImage: "gear").tag("Bezier")
                    //                    Label("Control point", systemImage: "gear").tag("Control point")
                }
                .pickerStyle(.segmented)
            }
            .customizationBehavior(.default)
        }
        .toolbarTitleDisplayMode(.automatic)
    }

    @ViewModifierBuilder
    var currentToolModifier: some ViewModifier {
        @Bindable var model = model

        let insert = { (shape: MyShape) in
            let shape = Identified<UUID, MyShape>(shape)
            model.shapes.append(shape)
            undoManager?.registerUndo(withTarget: model) { model in
                model.shapes.remove(identifiedBy: shape.id)
            }
        }

        switch model.currentTool {
        case .select:
            SelectTool(selection: $model.selection, shapes: $model.shapes)
        case .line:
            LineTool(editedShape: $model.editedShape) { insert(model.editedShape!) }
        case .circle:
            CircleTool(editedShape: $model.editedShape) { insert(model.editedShape!) }
        }
    }
}
