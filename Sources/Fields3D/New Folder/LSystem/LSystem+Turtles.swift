import SwiftUI

extension TurtleProtocol {
    mutating func applyLSystemState<Symbol>(_ state: [Symbol], rules: [Symbol: (inout Self) -> Void]) throws where Symbol: Hashable {
        for symbol in state {
            guard let rule = rules[symbol] else {
                fatalError("Cannot process symbol: \(symbol).")
            }
            rule(&self)
        }
    }
}
