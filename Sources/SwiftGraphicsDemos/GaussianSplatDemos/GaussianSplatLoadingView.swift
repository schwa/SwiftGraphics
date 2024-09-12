import BaseSupport
import GaussianSplatSupport
import SwiftUI
import Algorithms
import os

public struct GaussianSplatLoadingView: View {
    @Environment(\.metalDevice)
    private var device

    let url: URL
    let configuration: GaussianSplatRenderingConfiguration
    let splatLimit: Int?

    @State
    private var subtitle: String = "Processing"

    @State
    private var splatCloud: SplatCloud<SplatC>?

    public init(url: URL, initialConfiguration: GaussianSplatRenderingConfiguration, splatLimit: Int?) {
        self.url = url
        self.configuration = initialConfiguration
        self.splatLimit = splatLimit
    }

    public var body: some View {
        ZStack {
            if let splatCloud {

                let viewModel = try! GaussianSplatViewModel<SplatC>(device: device, splatCloud: splatCloud, configuration: configuration, logger: Logger())

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
                switch url.scheme {
                case "http", "https":
                    subtitle = "Downloading"

                    let session = URLSession.shared

                    var headRequest = URLRequest(url: url)
                    headRequest.httpMethod = "HEAD"

                    let (headData, headResponse) = try await session.data(for: headRequest)
                    guard let headResponse = (headResponse as? HTTPURLResponse) else {
                        fatalError("Oops")
                    }
                    let contentLength = (headResponse.allHeaderFields["Content-Length"] as? String).map(Int.init)
                    print(contentLength)

                    let request = URLRequest(url: url)
                    let (byteStream, response1) = try await session.bytes(for: request)
                    var splats: [SplatC] = []


                    let splatStream = byteStream.chunks(ofCount: MemoryLayout<SplatB>.stride).map { bytes in
                        bytes.withUnsafeBytes { buffer in
                            let splatB = buffer.load(as: SplatB.self)
                            let splatC = SplatC(splatB)
                            return splatC
                        }
                    }

                    for try await splat in splatStream {
                        splats.append(splat)
                    }

                    print("DONE LOOPING")
                    print(splats.count)


                    let (localURL, response) = try await session.download(for: request)
                    guard let response = response as? HTTPURLResponse else {
                        fatalError("Oops")
                    }
                    if response.statusCode != 200 {
                        throw BaseError.generic("Oops")
                    }
                    let symlinkURL = localURL.appendingPathExtension("splat")
                    try FileManager().createSymbolicLink(at: symlinkURL, withDestinationURL: localURL)
                    subtitle = "Processing"
                    splatCloud = try SplatCloud<SplatC>(device: device, url: symlinkURL, splatLimit: splatLimit)
                    print(splatCloud?.splats.count)
                default:
                    splatCloud = try SplatCloud<SplatC>(device: device, url: url, splatLimit: splatLimit)
                }
            }
            catch {
                fatalError(error)
            }
        }
    }
}
