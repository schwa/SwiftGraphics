public protocol ConverterProtocol {
    associatedtype Input
    associatedtype Output

    func convert(_ value: Input) throws -> Output
}
