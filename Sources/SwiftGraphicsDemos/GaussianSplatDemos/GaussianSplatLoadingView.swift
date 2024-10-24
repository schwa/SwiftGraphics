import BaseSupport
import Constraints3D
import GaussianSplatSupport
import os
import SwiftUI

public struct GaussianSplatLoadingView: View {
    @Environment(\.metalDevice)
    private var device

    let source: UFOSpecifier
    let configuration: GaussianSplatConfiguration

    @State
    private var subtitle: String = "Processing"

    @State
    private var viewModel: GaussianSplatViewModel<SplatC>?

    @AppStorage("ufo-progressive-load")
    private var progressiveLoad: Bool = true

    @AppStorage("ufo-view")
    private var useUFOView = false

    public init(source: UFOSpecifier) {
        self.source = source
        self.configuration = GaussianSplatConfiguration(skyboxTexture: GaussianSplatConfiguration.defaultSkyboxTexture(device: MTLCreateSystemDefaultDevice()!))
    }

    public var body: some View {
        ZStack {
            if let viewModel {
                if useUFOView {
                    UFOView(bounds: source.bounds)
                    .environment(viewModel)

                }
                else {
                    GaussianSplatView(bounds: source.bounds)
                        .environment(viewModel)
                }
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
                switch (progressiveLoad, source.url.scheme) {
                case (true, "http"), (true, "https"):
                    subtitle = "Streaming"
                    viewModel = try! await GaussianSplatViewModel<SplatC>(device: device, source: source, progressiveURL: source.url, configuration: configuration, logger: Logger())
                    Task.detached {
                        try await viewModel?.streamingLoad(url: source.url)
                    }
                case (false, "http"), (false, "https"):
                    subtitle = "Downloading"
                    Task.detached {
                        let session = URLSession.shared
                        let request = await URLRequest(url: source.url)
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
                            let splatCloud = try SplatCloud<SplatC>(device: device, url: url)
                            viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatCloud: splatCloud, configuration: configuration, logger: Logger())
                        }
                    }
                default:
                    let splatCloud = try SplatCloud<SplatC>(device: device, url: source.url)
                    viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatCloud: splatCloud, configuration: configuration, logger: Logger())
                }
            }
            catch {
                fatalError(error)
            }
        }
    }
}

extension GaussianSplatViewModel where Splat == SplatC {
    public convenience init(device: MTLDevice, source: UFOSpecifier, progressiveURL url: URL, configuration: GaussianSplatConfiguration, logger: Logger? = nil) async throws {
        assert(MemoryLayout<SplatB>.stride == MemoryLayout<SplatB>.size)
        let session = URLSession.shared
        // Perform a HEAD request to compute the number of splats.
        var headRequest = URLRequest(url: url)
        headRequest.httpMethod = "HEAD"
        let (_, headResponse) = try await session.data(for: headRequest)
        guard let headResponse = headResponse as? HTTPURLResponse else {
            fatalError("Oops")
        }
        guard headResponse.statusCode == 200 else {
            throw BaseError.missingResource
        }
        guard let contentLength = try (headResponse.allHeaderFields["Content-Length"] as? String).map(Int.init)?.safelyUnwrap(BaseError.optionalUnwrapFailure) else {
            fatalError("Oops")
        }
        guard contentLength.isMultiple(of: MemoryLayout<SplatB>.stride) else {
            fatalError("Not an even multiple of \(MemoryLayout<SplatB>.stride)")
        }
        let splatCount = contentLength / MemoryLayout<SplatB>.stride

        try self.init(device: device, splatCapacity: splatCount, configuration: configuration, logger: logger)
    }

    func streamingLoad(url: URL) async throws {
        let session = URLSession.shared
        loadProgress.totalUnitCount = Int64(splatCloud.capacity)
        let request = URLRequest(url: url)
        let (byteStream, bytesResponse) = try await session.bytes(for: request)
        guard let bytesResponse = bytesResponse as? HTTPURLResponse else {
            fatalError("Oops")
        }
        guard bytesResponse.statusCode == 200 else {
            throw BaseError.missingResource
        }
        let splatStream = byteStream.chunks(ofCount: MemoryLayout<SplatB>.stride).map { bytes in
            bytes.withUnsafeBytes { buffer in
                let splatB = buffer.load(as: SplatB.self)
                return SplatC(splatB)
            }
        }
        .chunks(ofCount: 2048)
        for try await splats in splatStream {
            try splatCloud.append(splats: splats)
            self.requestSort()
            loadProgress.completedUnitCount = Int64(splatCloud.count)
        }
        assert(splatCloud.count == splatCloud.capacity)
    }
}
