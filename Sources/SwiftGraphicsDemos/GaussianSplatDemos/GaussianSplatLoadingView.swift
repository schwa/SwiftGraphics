import BaseSupport
import Constraints3D
import GaussianSplatSupport
import os
import SwiftUI

public struct GaussianSplatLoadingView: View {
    @Environment(\.metalDevice)
    private var device

    let url: URL
    let splatResource: SplatResource
    let configuration: GaussianSplatConfiguration
    let splatLimit: Int?
    let progressiveLoad: Bool
    let bounds: ConeBounds

    @State
    private var subtitle: String = "Processing"

    @State
    private var viewModel: GaussianSplatViewModel<SplatC>?

    public init(url: URL, splatResource: SplatResource, bounds: ConeBounds, initialConfiguration: GaussianSplatConfiguration, splatLimit: Int?, progressiveLoad: Bool) {
        self.url = url
        self.splatResource = splatResource
        self.bounds = bounds
        self.configuration = initialConfiguration
        self.splatLimit = splatLimit
        self.progressiveLoad = progressiveLoad
    }

    public var body: some View {
        ZStack {
            if let viewModel {
                GaussianSplatView(bounds: bounds)
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
                    viewModel = try! await GaussianSplatViewModel<SplatC>(device: device, splatResource: splatResource, progressiveURL: url, configuration: configuration, logger: Logger())
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
                            viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatResource: splatResource, splatCloud: splatCloud, configuration: configuration, logger: Logger())
                        }
                    }
                default:
                    let splatCloud = try SplatCloud<SplatC>(device: device, url: url, splatLimit: splatLimit)
                    viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatResource: splatResource, splatCloud: splatCloud, configuration: configuration, logger: Logger())
                }
            }
            catch {
                fatalError(error)
            }
        }
    }
}

extension GaussianSplatViewModel where Splat == SplatC {
    public convenience init(device: MTLDevice, splatResource: SplatResource, progressiveURL url: URL, configuration: GaussianSplatConfiguration, logger: Logger? = nil) async throws {
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
        print("Content length: \(contentLength), splat count: \(splatCount)")

        try self.init(device: device, splatResource: splatResource, splatCapacity: splatCount, configuration: configuration, logger: logger)
    }

    func streamingLoad(url: URL) async throws {
        //        assert(MemoryLayout<SplatB>.stride == MemoryLayout<SplatB>.size)
        //
        let session = URLSession.shared

        loadProgress.totalUnitCount = Int64(splatCloud.capacity)

        // Start loading splats into a new splat cloud with the right capacity...
        //        splatCloud = try SplatCloud<Splat>(device: device, capacity: splatCount)
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
