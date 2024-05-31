import MetalSupport
import SwiftGraphicsSupport

public protocol PolygonConverterProtocol: ConverterProtocol {
    associatedtype Input

    init()
    func convert(_ value: Input) throws -> [Polygon3D<SimpleVertex>]
}

public protocol PolygonConvertable {
    associatedtype PolygonConverter: PolygonConverterProtocol where PolygonConverter.Input == Self
}

public extension PolygonConvertable {
    func toPolygons() throws -> [Polygon3D<SimpleVertex>] {
        let converter = PolygonConverter()
        return try converter.convert(self)
    }
}
