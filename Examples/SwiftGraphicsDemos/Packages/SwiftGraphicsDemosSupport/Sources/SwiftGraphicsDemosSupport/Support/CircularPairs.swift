// TODO: Can this be replaced/arugmented by something in SwiftAlgorithms?

extension Sequence {
    func circularPairs() -> CircularPairsSequence<Self> {
        CircularPairsSequence(base: self)
    }
}

struct CircularPairsSequence<Base: Sequence> {
    var base: Base
}

extension CircularPairsSequence: Sequence {
    func makeIterator() -> Iterator {
        Iterator(base: base.makeIterator())
    }

    struct Iterator: IteratorProtocol {
        var base: Base.Iterator
        var first: Base.Element?
        var previous: Base.Element?
        var atEnd = false

        mutating func next() -> (Base.Element, Base.Element)? {
            switch (base.next(), first, previous, atEnd) {
            case (.none, .none, .none, false):
                return nil
            case (.some(let current), .none, .none, false):
                guard let next = base.next() else {
                    return (current, current)
                }
                first = current
                previous = next
                return (current, next)
            case (.some(let current), .some, .some(let previous), false):
                self.previous = current
                return (previous, current)
            case (.none, .some(let first), .some(let previous), false):
                atEnd = true
                return (previous, first)
            case (_, _, _, true):
                return nil
            default:
                unreachable()
            }
        }
    }
}
