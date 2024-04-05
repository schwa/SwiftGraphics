import SwiftUI

struct PathEditor <Data>: View where Data: MutableCollection & RandomAccessCollection, Data.Index: Hashable {

    typealias Element = Data.Element

    @Binding
    var data: Data
    var idForElement: (Element) -> AnyHashable
    var position: WritableKeyPath<Data.Element, CGPoint>

    init<ID>(data: Binding<Data>, id: KeyPath<Element, ID>, position: WritableKeyPath<Element, CGPoint>) where ID: Hashable {
        self._data = data
        self.idForElement = {
            AnyHashable($0[keyPath: id])
        }
        self.position = position
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                let positions = data.map { $0[keyPath: position] }
                let path = Path { path in
                    path.addLines(positions)
                }
                context.stroke(path, with: .color(.black))
            }
            ForEach(data.indices, id: \.self) { index in
                let binding = bindingForPosition(of: bindingForElement(at: index))
                return Handle(binding)
            }
        }
    }

    func bindingForElement(at index: Data.Index) -> Binding<Element> {
        Binding {
            data[index]
        } set: { newValue in
            data[index] = newValue
        }
    }

    func bindingForPosition(of element: Binding<Element>) -> Binding<CGPoint> {
        Binding {
            element.wrappedValue[keyPath: position]
        } set: { newValue in
            element.wrappedValue[keyPath: position] = newValue
        }
    }

    func actions(for element: Element) -> some View {
        Button("Remove") {
        }
    }

}


struct PathEditorDemo: View {

    @State
    var points: [CGPoint] = [[10, 10], [100, 10]]


    var body: some View {
        let binding = Binding {
            Array(points.enumerated())
        } set: { newValue in
            points = newValue.map(\.1)
        }
        PathEditor(data: binding, id: \.0, position: \.1)
    }

}



