public protocol CompositePassProtocol: PassProtocol {
    func children() throws -> [any PassProtocol]
}
