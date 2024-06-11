import simd

extension simd_quatd: Codable {
    enum CodingKeys: CodingKey {
        case real
        case imaginary
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let real = try container.decode(Double.self, forKey: .real)
        let imaginary = try container.decode(SIMD3<Double>.self, forKey: .imaginary)
        self = .init(real: real, imag: imaginary)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(real, forKey: .real)
        try container.encode(imag, forKey: .imaginary)
    }
}
