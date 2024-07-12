public enum BaseError: Error {
    case generic(String)
    case resourceCreationFailure
    case illegalValue
    case optionalUnwrapFailure
}
