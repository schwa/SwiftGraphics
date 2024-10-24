import Constraints3D
import GaussianSplatSupport
import MetalKit
import RenderKit
import SwiftUI

public struct GaussianSplatLobbyView: View {
    @Binding
    private var navigationPath: NavigationPath

    let sources: [UFOSpecifier]

    @AppStorage("gpu-counters")
    private var useGPUCounters = false

    @AppStorage("ufo-progressive-load")
    private var progressiveLoad: Bool = true

    @AppStorage("ufo-view")
    private var useUFOView = false

    init(navigationPath: Binding<NavigationPath>, sources: [UFOSpecifier]) {
        self._navigationPath = navigationPath
        self.sources = sources
    }

    public var body: some View {
        List {
            Section("UFOs") {
                                ForEach(sources, id: \.self) { source in
                                    Label {
                        NavigationLink(source.name, value: NavigationAtom.ufo(source))
                            .frame(maxWidth: .infinity)
                                    } icon: {
                                        switch source.url.scheme {
                                        case "file":
                                            Image(systemName: "doc")
                                        case "http", "https":
                                            Image(systemName: "globe")
                                        default:
                                            EmptyView()
                                        }
                                    }
                                    .tag(source)
                            }
                        }
            Section("Options") {
                Toggle(isOn: $progressiveLoad) {
                    HStack {
                        Text("Progressive Load")
                        Spacer()
                        PopupHelpButton(help: "Use HTTP streaming to load splats progressively.")
                    }
                    }
                Toggle(isOn: $useGPUCounters) {
                    HStack {
                        Text("Use GPU Counters")
                        Spacer()
                        PopupHelpButton(help: "TODO")
                    }
                }
                .disabled(true)
                Toggle(isOn: $useUFOView) {
                    HStack {
                        Text("UFOView")
                        Spacer()
                        PopupHelpButton(help: "Uses a reduce-functionality `UFOView` to render the splats. This view doesn't have any bells & whistles that are only useful for testing/debugging.")
                    }
                    }


                }
                }
                #if os(macOS)
                .frame(width: 320)
                #endif
    }
}
