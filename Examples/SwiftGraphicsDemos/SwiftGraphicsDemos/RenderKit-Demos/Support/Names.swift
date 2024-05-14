import Foundation

// https://github.com/fnichol/names

struct Names {
    static let shared = Self()

    let adjectives: [String.SubSequence]
    let nouns: [String.SubSequence]

    init() {
        do {
            adjectives = try String(contentsOf: Bundle.main.url(forResource: "adjectives", withExtension: "txt")!).split(whereSeparator: \.isNewline)
            nouns = try String(contentsOf: Bundle.main.url(forResource: "nouns", withExtension: "txt")!).split(whereSeparator: \.isNewline)
        }
        catch {
            fatalError("\(error)")
        }
    }

    func random(pad: Int? = nil) -> String {
        let adjective = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        if let pad {
            let max = Int(pow(10, Double(pad)))
            let pad = Int.random(in: 1 ..< max)
            return "\(adjective)-\(noun)-\(pad)"
        }
        else {
            return "\(adjective)-\(noun)"
        }
    }

    func hashed(hashable value: some Hashable, pad: Int? = nil) -> String {
        var value = abs(value.hashValue)
        let adjective = adjectives[value % adjectives.count]
        value /= adjectives.count
        let noun = nouns[value % nouns.count]
        value /= nouns.count
        if let pad {
            let padCount = Int(pow(10, Double(pad))) - 1
            let pad = value % padCount
            value /= padCount
            return "\(adjective)-\(noun)-\(pad)"
        }
        else {
            return "\(adjective)-\(noun)"
        }
    }
}
