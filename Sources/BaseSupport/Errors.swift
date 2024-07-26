public enum BaseError: Error {
    case generic(String)
    case resourceCreationFailure
    case illegalValue
    case optionalUnwrapFailure
    case initializationFailure
    case unknown
    case missingValue
    case typeMismatch
    case inputOutputFailure
    case invalidParameter
    case parsingFailure
    case encodingFailure
    case missingResource
    case extended(Error, String)
}

public func fatalError(_ error: Error) -> Never {
    fatalError("\(error)")
}

public func unimplemented(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError(message(), file: file, line: line)
}

public func temporarilyDisabled(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError(message(), file: file, line: line)
}

public func unreachable(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError(message(), file: file, line: line)
}
