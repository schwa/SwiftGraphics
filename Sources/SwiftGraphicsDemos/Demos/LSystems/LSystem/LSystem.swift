// https://en.wikipedia.org/wiki/L-system

struct LSystem <Symbol> where Symbol: Hashable {
    var initialState: [Symbol]
    var rules: [Symbol: [Symbol]]
}

extension LSystem: Sendable where Symbol: Sendable {
}

extension LSystem {
    func apply(state: [Symbol]) -> [Symbol] {
        Array(state.map { symbol in
            rules[symbol] ?? [symbol]
        }.joined())
    }

    func apply() -> [Symbol] {
        apply(state: initialState)
    }

    func apply(iterations: Int) -> [Symbol] {
        var state = initialState
        for _ in 0..<iterations {
            state = apply(state: state)
        }
        return state
    }
}

extension LSystem where Symbol == Character {
    init(initialState: String, rules: [Character: String]) {
        self.initialState = Array(initialState)
        self.rules = rules.mapValues {
            Array($0)
        }
    }
}

extension LSystem where Symbol == Character {
    static let algae = LSystem(initialState: "A", rules: [
        "A": "AB",
        "B": "A",
    ])

    static let fractalBinaryTree = LSystem(initialState: "0", rules: [
        "1": "11",
        "0": "1[0]0",
    ])

    static let sierpinskiTriangle = LSystem(initialState: "F-G-G", rules: [
        "F": "F-G+F+G-F",
        "G": "GG",
    ])

    static let dragonCurve = LSystem(initialState: "F", rules: [
        "F": "F+G",
        "G": "F-G",
    ])

    static let hilbertCurve = LSystem(initialState: "A", rules: [
        "A": "+BF-AFA-FB+",
        "B": "-AF+BFB+FA-",
        "F": "",
    ])
}
