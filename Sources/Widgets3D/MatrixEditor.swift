import Foundation
import simd
import SwiftFormats
import SwiftUI

extension Binding where Value: FormattableMatrix & Sendable {
    subscript(column: Int, row: Int) -> Binding<Value.Scalar> {
        Binding<Value.Scalar> {
            self.wrappedValue[column, row]
        }
        set: {
            self.wrappedValue[column, row] = $0
        }
    }
}

public struct MatrixEditor <Matrix>: View where Matrix: FormattableMatrix & MatrixOperations & Sendable, Matrix.Scalar == Float {
    @Binding
    var matrix: Matrix

    private var formatStyle: FloatingPointFormatStyle<Float> {
        scientificNotation ? .number.notation(.scientific) : .number.precision(.significantDigits(0...100))
    }

    @State
    private var formatSign: Bool = false

    @State
    private var scientificNotation: Bool = false

    @Environment(\.undoManager)
    var undoManager

    public init(_ matrix: Binding<Matrix>) {
        self._matrix = matrix
    }

    public var body: some View {
        HStack {
            Group {
                Grid {
                    ForEach(0..<matrix.rowCount, id: \.self) { row in
                        GridRow {
                            ForEach(0..<matrix.columnCount, id: \.self) { column in
                                cell(for: $matrix[column, row])
                            }
                        }
                    }
                }
            }
            Menu {
                actions()
            }
            label: {
                Image(systemName: "gear")
            }
            .fixedSize()
            .menuStyle(.borderlessButton)
        }
    }

    @ViewBuilder
    func cell(for value: Binding<Matrix.Scalar>) -> some View {
        TextField("", value: value, format: formatStyle)
            .lineLimit(1)
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .trailing)
            .foregroundColor(formatSign == false ? .primary : (value.wrappedValue == 0 ? .primary : (value.wrappedValue < 0 ? .red : .green)))
    }

    @ViewBuilder
    func actions() -> some View {
        #if os(macOS)
        Button("Copy") {
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.tabularText, .string], owner: nil)
            pasteboard.setString(matrix.tabularPasteboardRepresentation, forType: .tabularText)
            pasteboard.setString(matrix.tabularPasteboardRepresentation, forType: .string)
        }
        Button("Copy as Swift") {
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(matrix.swiftSourceRepresentation, forType: .string)
        }
        Button("Paste") {
            let pasteboard = NSPasteboard.general
            let string = pasteboard.string(forType: .tabularText) ?? ""
            guard let matrix = try? Matrix(tabularPasteboardRepresentation: string) else {
                fatalError("Failed to parse pasted matrix")
            }
            self.matrix = matrix
        }
        Divider()
        #endif // os(macOS)
        Button("Zero") {
            undoManager?.registerUndoValue($matrix)
            matrix = Matrix.zero
        }
        Button("Identity") {
            undoManager?.registerUndoValue($matrix)
            matrix = Matrix.identity
        }
        Button("Invert") {
            undoManager?.registerUndoValue($matrix)
            matrix = matrix.inverse
        }
        Button("Transpose") {
            undoManager?.registerUndoValue($matrix)
            matrix = matrix.transpose
        }
        Divider()
        Toggle("Format Sign", isOn: $formatSign)
        Toggle("Scientific Notation", isOn: $scientificNotation)
    }
}

// MARK: -



public protocol MatrixOperations {
    static var zero: Self { get }
    static var identity: Self { get }
    var inverse: Self { get }
    var transpose: Self { get }
}

extension simd_float4x4: MatrixOperations {
    public static var zero: Self {
        .init()
    }
}

extension simd_float3x3: MatrixOperations {
    public static var zero: Self {
        .init()
    }
}

extension String {
    var lines: [String] {
        var lines: [String] = []
        self.enumerateLines { line, _ in
            lines.append(line)
        }
        return lines
    }
}

extension FormattableMatrix where Scalar == Float {
    init(tabularPasteboardRepresentation string: String) throws {
        // TODO: Terrible :-)
        self.init()
        for (row, line) in string.lines.enumerated() {
            for (column, cell) in line.split(separator: "\t").enumerated() {
                if column >= columnCount || row >= rowCount {
                    fatalError("Invalid matrix size")
                }
                guard let value = Float(cell) else {
                    fatalError("Invalid cell value")
                }
                self[column, row] = value
            }
        }
    }

    var tabularPasteboardRepresentation: String {
        (0..<rowCount).map { row in
            (0..<columnCount).map { column in
                self[column, row].formatted()
            }.joined(separator: "\t")
        }.joined(separator: "\n")
    }

    var swiftSourceRepresentation: String {
        let values = (0..<columnCount).map { column in
            (0..<rowCount).map { row in
                self[column, row].formatted()
            }.joined(separator: ",")
        }.map { "[\($0)]" }.joined(separator: ",")
        return "simd_float\(columnCount)x\(rowCount)([\(values)])"
    }
}

#Preview {
    @Previewable @State var matrix = simd_float4x4()
    Form {
        MatrixEditor($matrix)
        MatrixView(matrix)
    }
}

extension UndoManager {
    func registerUndoValue<Value>(_ binding: Binding<Value>) where Value: Sendable {
        let copy = binding.wrappedValue
        registerUndo(withTarget: self) { _ in
            binding.wrappedValue = copy
        }
    }

    //    func registerUndo<Root, Value>(root: inout Root, keyPath: WritableKeyPath<Root, Value>) {
    //        let copy = root[keyPath: keyPath]
    //        registerUndo(withTarget: self) { _ in
    //            root[keyPath: keyPath] = copy
    //        }
    //    }
}
