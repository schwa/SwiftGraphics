import SwiftUI

struct SketchScene: Scene {
    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        WindowGroup {
            SketchView()
                .toolbar {
                    Button("Demos") {
                        openWindow(id: "demos")
                    }
                }
        }
        .commands {
            InspectorCommands()
            SidebarCommands()
            ToolbarCommands()
            //            TextEditingCommands()
            //            TextFormattingCommands()
            //            CommandGroup(after: .windowList) {
            //                Button("Demos") {
            //                    openWindow(id: "demos")
            //                }
            //                .keyboardShortcut("D", modifiers: [.command, .shift])
            //            }
        }
    }
}
