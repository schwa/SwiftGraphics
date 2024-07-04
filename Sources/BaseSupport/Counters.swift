import Algorithms
import Charts
import Everything
import Foundation
import Observation
import SwiftUI

public actor Counters {
    public static let shared = Counters()

    public struct Record: Identifiable, Sendable {
        public var id: String
        public var count: Int = 0
        public var first: TimeInterval
        public var last: TimeInterval
        public var lastInterval: Double = 0
        public var meanInterval: Double = 0
        public var movingAverageInterval = ExponentialMovingAverageIrregular()
        public var history: [TimeInterval]
    }

    @ObservationIgnored
    var records: [String: Record] = [:]

    func _increment(counter key: String) {
        let now = Date.now.timeIntervalSinceReferenceDate
        if var record = records[key] {
            record.count += 1
            let last = record.last
            record.last = now
            record.lastInterval = now - last
            record.meanInterval = (record.last - record.first) / Double(record.count)
            record.movingAverageInterval.update(time: now - record.first, value: now - last)
            record.history = Array((record.history + [now]).drop { time in
                now - time > 10
            })
            records[key] = record
        }
        else {
            records[key] = Record(id: key, first: now, last: now, history: [now])
        }
    }

    nonisolated
    public func increment(counter key: String) {
        Task {
            await _increment(counter: key)
        }
    }
}

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
                    Text("\(record.count, format: .number)")
                        .monospacedDigit()
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
