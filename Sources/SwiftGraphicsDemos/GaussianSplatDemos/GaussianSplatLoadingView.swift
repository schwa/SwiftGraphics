import BaseSupport
import Constraints3D
import GaussianSplatSupport
import os
import SwiftUI

public struct GaussianSplatLoadingView: View {
    @Environment(\.metalDevice)
    private var device

    let url: URL
    let configuration: GaussianSplatRenderingConfiguration
    let splatLimit: Int?
    let progressiveLoad: Bool
    let bounds: ConeBounds

    @State
    private var subtitle: String = "Processing"

    @State
    private var viewModel: GaussianSplatViewModel<SplatC>?

    public init(url: URL, bounds: ConeBounds, initialConfiguration: GaussianSplatRenderingConfiguration, splatLimit: Int?, progressiveLoad: Bool) {
        self.url = url
        self.bounds = bounds
        self.configuration = initialConfiguration
        self.splatLimit = splatLimit
        self.progressiveLoad = progressiveLoad
    }

    public var body: some View {
        ZStack {
            if let viewModel {
                GaussianSplatNewMinimalView()
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
                switch (progressiveLoad, url.scheme) {
                case (true, "http"), (true, "https"):
                    subtitle = "Streaming"
                    viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatCount: 0, bounds: bounds, configuration: configuration, logger: Logger())
                    Task.detached {
                        try await viewModel?.streamingLoad(url: url)
                    }
                case (false, "http"), (false, "https"):
                    subtitle = "Downloading"
                    Task.detached {
                        let session = URLSession.shared
                        let request = URLRequest(url: url)
                        let (downloadedUrl, response) = try await session.download(for: request)
                        guard let response = response as? HTTPURLResponse else {
                            fatalError("Oops")
                        }
                        guard response.statusCode == 200 else {
                            throw BaseError.missingResource
                        }
                        let url = downloadedUrl.appendingPathExtension("splat")
                        try FileManager().createSymbolicLink(at: url, withDestinationURL: downloadedUrl)
                        try await MainActor.run {
                            let splatCloud = try SplatCloud<SplatC>(device: device, url: url, splatLimit: splatLimit)
                            viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatCloud: splatCloud, bounds: bounds, configuration: configuration, logger: Logger())
                        }
                    }
                default:
                    let splatCloud = try SplatCloud<SplatC>(device: device, url: url, splatLimit: splatLimit)
                    viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatCloud: splatCloud, bounds: bounds, configuration: configuration, logger: Logger())
                }
            }
            catch {
                fatalError(error)
            }
        }
    }
}
