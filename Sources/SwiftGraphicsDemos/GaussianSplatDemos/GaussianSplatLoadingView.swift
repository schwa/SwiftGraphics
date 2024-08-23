import BaseSupport
import GaussianSplatSupport
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
    private var splatCloud: SplatCloud<SplatC>?

    public init(url: URL, initialConfiguration: GaussianSplatRenderingConfiguration, splatLimit: Int?) {
        self.url = url
        self.configuration = initialConfiguration
        self.splatLimit = splatLimit
    }

    public var body: some View {
        ZStack {
            if let splatCloud {
                GaussianSplatNewMinimalView(splatCloud: splatCloud, configuration: configuration)
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
                    let request = URLRequest(url: url)
                    let (localURL, response) = try await URLSession.shared.download(for: request)
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
