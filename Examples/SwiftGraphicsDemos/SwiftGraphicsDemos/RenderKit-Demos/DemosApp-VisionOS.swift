#if os(visionOS)
    import CompositorServices
    import RenderKit
    import SwiftUI

    /*
     <?xml version="1.0" encoding="UTF-8"?>
     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
     <plist version="1.0">
     <dict>
         <key>UISceneConfigurations</key>
         <dict/>
         <key>UIApplicationSupportsMultipleScenes</key>
         <true/>
         <key>UIApplicationPreferredDefaultSceneSessionRole</key>
         <string>UIWindowSceneSessionRoleVolumetricApplication</string>
     </dict>
     </plist>
      */

    @main
    struct DemosApp: App {
        var body: some Scene {
            WindowGroup {
                ContentView()
            }.windowStyle(.volumetric)
            ImmersiveSpace(id: "ImmersiveSpace") {
                CompositorLayer(configuration: ContentStageConfiguration()) { layerRenderer in
                    try! Renderer(layerRenderer).startRenderLoop()
                }
            }
            .immersionStyle(selection: .constant(.full), in: .full)
        }
    }
#endif
