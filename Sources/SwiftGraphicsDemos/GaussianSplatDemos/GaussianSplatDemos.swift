import Foundation
import GaussianSplatSupport

extension GaussianSplatLobbyView: DemoView {
    static let testData: [SplatResource] = [
        .init(name: "Test 1", url: URL(string: "https://s.zillowstatic.com/z3d-home/models/ufo_demo/test1.splat")!, bounds: .init(bottomHeight: 0.05, bottomInnerRadius: 0.4, topHeight: 0.8, topInnerRadius: 0.8)),
        .init(name: "Test 2", url: URL(string: "https://s.zillowstatic.com/z3d-home/models/ufo_demo/test2.splat")!, bounds: .init(bottomHeight: 0.08, bottomInnerRadius: 0.8, topHeight: 1, topInnerRadius: 0.9)),
        .init(name: "Test 3", url: URL(string: "https://s.zillowstatic.com/z3d-home/models/ufo_demo/test3.splat")!, bounds: .init(bottomHeight: -0.09, bottomInnerRadius: 0.6, topHeight: 0.9, topInnerRadius: 1.3)),
        .init(name: "Steve 1", url: URL(string: "https://s.zillowstatic.com/z3d-home/models/ufo_demo/steve_1.splat")!, bounds: .init(bottomHeight: 0.085, bottomInnerRadius: 0.25, topHeight: 0.7, topInnerRadius: 0.9)),
    ]

    init() {
        self.init(sources: Self.testData)

        //                    [
        //            //            Bundle.main.url(forResource: "vision_dr", withExtension: "splat", recursive: true)!,
        //            URL(string: "https://s.zillowstatic.com/z3d-home/models/ufo_demo/test1.splat")!,
        //            URL(string: "https://s.zillowstatic.com/z3d-home/models/ufo_demo/steve_1.splat")!,
        //        ])
    }
}
