import SwiftUI

@main
struct VectorLaboratoryApp: App {

    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
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

        Window("Demos", id: "demos") {
            DemosView()
        }
    }
}

