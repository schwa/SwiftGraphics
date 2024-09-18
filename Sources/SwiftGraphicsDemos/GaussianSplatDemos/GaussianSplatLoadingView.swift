import BaseSupport
import GaussianSplatSupport
import os
import SwiftUI

public struct GaussianSplatLoadingView: View {
    @Environment(\.metalDevice)
    private var device

    let url: URL
    let configuration: GaussianSplatRenderingConfiguration
    let splatLimit: Int?

    @State
    private var subtitle: String = "Processing"

    @State
    private var viewModel: GaussianSplatViewModel<SplatC>?

    public init(url: URL, initialConfiguration: GaussianSplatRenderingConfiguration, splatLimit: Int?) {
        self.url = url
        self.configuration = initialConfiguration
        self.splatLimit = splatLimit
    }

    public var body: some View {
        ZStack {
            if let viewModel {
                GaussianSplatNewMinimalView(bounds: .init(bottomHeight: 0.05, bottomInnerRadius: 0.4, topHeight: 0.8, topInnerRadius: 0.8))
                    .environment(viewModel)
            }
            else {
                VStack {
                    ProgressView()
                    Text(subtitle)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            do {
                switch url.scheme {
                case "http", "https":
                    subtitle = "Downloading"
                    viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatCount: 0, configuration: configuration, logger: Logger())
                    Task.detached {
                        try await viewModel?.streamingLoad(url: url)
                    }
                default:
                    let splatCloud = try SplatCloud<SplatC>(device: device, url: url, splatLimit: splatLimit)
                    viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatCloud: splatCloud, configuration: configuration, logger: Logger())
                }
            }
            catch {
                fatalError(error)
            }
        }
    }
}
