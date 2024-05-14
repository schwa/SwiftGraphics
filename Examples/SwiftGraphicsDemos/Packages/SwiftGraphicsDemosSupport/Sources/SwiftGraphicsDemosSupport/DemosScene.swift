import SwiftUI

public struct DemosScene: Scene {

    public init() {
    }

    public var body: some Scene {
#if os(macOS)
        Window("Demos", id: "demos") {
            DemosView()
        }
#endif
    }

}
