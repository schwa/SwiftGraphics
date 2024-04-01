public enum MetalSupportError: Error {
    case illegalValue
}

func fatal(error: Error) -> Never {
    fatalError("\(error)")
}
