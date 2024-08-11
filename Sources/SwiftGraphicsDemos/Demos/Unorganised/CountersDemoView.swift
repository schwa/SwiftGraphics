import Counters
import SwiftUI

struct CountersDemoView: DemoView {
    var body: some View {
        CountersView()
            .task {
                do {
                    while true {
                        Counters.shared.increment(counter: "Hello world")
                        try await Task.sleep(for: .seconds(0.1))
                    }
                } catch {
                }
            }
    }
}
