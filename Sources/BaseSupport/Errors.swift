public enum BaseError: Error {
    // IDEA: Have a good going over here and clean up duplicate/vague types.
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
    case decodingFailure
    case missingBinding(String)
}

public extension BaseError {
    static func error(_ error: Self) -> Self {
        // NOTE: Hook here to add logging or special breakpoint handling.
        //        logger?.error("Error: \(error)")
        error
    }
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

// MARK: -

public extension Optional {
    func safelyUnwrap(_ error: @autoclosure () -> Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error()
        }
        return wrapped
    }

    func forceUnwrap() -> Wrapped {
        guard let wrapped = self else {
            fatalError("Cannot unwrap nil optional.")
        }
        return wrapped
    }

    func forceUnwrap(_ message: @autoclosure () -> String) -> Wrapped {
        guard let wrapped = self else {
            fatalError(message())
        }
        return wrapped
    }
}
