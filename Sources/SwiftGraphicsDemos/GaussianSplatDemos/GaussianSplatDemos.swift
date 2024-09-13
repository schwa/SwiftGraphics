import Foundation

extension GaussianSplatLobbyView: DemoView {
    init() {
        self.init(sources: [
            Bundle.main.url(forResource: "vision_dr", withExtension: "splat", recursive: true)!,
            URL(string: "https://s.zillowstatic.com/z3d-home/models/ufo_demo/test1.splat")!,
            URL(string: "https://s.zillowstatic.com/z3d-home/models/ufo_demo/steve_1.splat")!,
        ])
    }
}
