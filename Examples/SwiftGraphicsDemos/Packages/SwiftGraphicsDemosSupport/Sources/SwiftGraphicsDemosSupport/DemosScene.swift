import SwiftUI

public struct DemosScene: Scene {
    public init() {
        print(Bundle.module)
    }

    public var body: some Scene {
#if os(macOS)
        Window("Demos", id: "demos") {
            DemosView()
        }
#else
        WindowGroup("Demos", id: "demos") {
            DemosView()
        }
#endif
    }
}
