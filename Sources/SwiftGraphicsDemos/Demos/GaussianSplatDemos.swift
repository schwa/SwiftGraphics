import Foundation

extension GaussianSplatNewMinimalView: DemoView {
    init() {
        let url = Bundle.main.url(forResource: "vision_dr", withExtension: "splat", recursive: true)!
        try! self.init(url: url)
    }
}

 extension SingleSplatView: DemoView {
 }
