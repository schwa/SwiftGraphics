import SwiftUI

@main
struct SwiftGraphicsDemosApp: App {
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

        #if os(macOS)
        Window("Demos", id: "demos") {
            DemosView()
        }
        #endif
    }
}
