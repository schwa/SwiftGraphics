public enum BaseError: Error {
    case generic(String)
    case resourceCreationFailure
    case illegalValue
    case optionalUnwrapFailure
    case initializationFailure
    case unknown
    case missingValue
    case typeMismatch
}
