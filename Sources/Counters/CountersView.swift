import Observation
import SwiftUI

public struct CountersView: View {
    let startDate = Date.now

    @State
    private var records: [Counters.Record] = []

    public init() {
    }

    public var body: some View {
        VStack {
            Table(records) {
                TableColumn("Counter") { record in
                    Text(record.id)
                }
                .width(min: 50, ideal: 50)
                TableColumn("Count") { record in
                    if case let .count(count) = record.value {
                        Text("\(count, format: .number)")
                            .monospacedDigit()
                    }
                }
                .width(min: 50, ideal: 50)
                TableColumn("Mean") { record in
                    let interval = record.meanInterval
                    let frequency = interval == 0 ? 0 : 1 / interval
                    Text("\(frequency, format: .number.precision(.fractionLength(2)))")
                        .monospacedDigit()
                }
                .width(min: 50, ideal: 50)
                TableColumn("EMAI") { record in
                    let interval = record.movingAverageInterval.exponentialMovingAverage
                    let frequency = interval == 0 ? 0 : 1 / interval
                    Text("\(frequency, format: .number.precision(.fractionLength(2)))")
                        .monospacedDigit()
                }
                .width(min: 50, ideal: 50)
                TableColumn("Current") { record in
                    let interval = record.lastInterval
                    let frequency = interval == 0 ? 0 : 1 / interval
                    Text("\(frequency, format: .number.precision(.fractionLength(2)))")
                        .monospacedDigit()
                }
                .width(min: 50, ideal: 50)
            }
            .controlSize(.small)
        }

        .task {
            do {
                while true {
                    try await Task.sleep(for: .seconds(1))
                    let records = await Array(Counters.shared.records.values.sorted(by: \.first))
                    await MainActor.run {
                        self.records = records
                    }
                }
            }
            catch {
            }
        }
    }
}
