import BaseSupport
import CoreGraphics
import Foundation
import GaussianSplatSupport
import Metal
import RenderKit
import RenderKitSceneGraph
import SwiftUI
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

// MARK: -

extension Int {
    var toDouble: Double {
        get {
            Double(self)
        }
        set {
            self = Int(newValue)
        }
    }
}

extension SceneGraph {
    // TODO: Rename - `unsafeSplatsNode`
    var splatsNode: Node {
        get {
            let accessor = self.firstAccessor(label: "splats")!
            return self[accessor: accessor]!
        }
        set {
            let accessor = self.firstAccessor(label: "splats")!
            self[accessor: accessor] = newValue
        }
    }
}

extension UTType {
    static let splat = UTType(filenameExtension: "splat")!
}

struct PopupHelpButton: View {
    @State
    private var isPresented: Bool = false

    var help: String

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "questionmark.circle")
        }
        #if os(macOS)
        .buttonStyle(.link)
        #endif
        .popover(isPresented: $isPresented) {
            Text(help)
                .font(.caption)
                .padding()
            #if os(iOS)
            .frame(maxHeight: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .presentationCompactAdaptation(.popover)
            #endif
        }
    }
}
