public protocol GroupPassProtocol: PassProtocol {
    func children() throws -> [any PassProtocol]
}
