import Algorithms
import Charts
import Everything
import Foundation

public actor Counters {
    public static let shared = Counters()

    struct Record: Identifiable, Sendable {
        var id: String
        var value: Value
        var first: TimeInterval
        var last: TimeInterval
        var lastInterval: Double = 0
        var meanInterval: Double = 0
        var movingAverageInterval = ExponentialMovingAverageIrregular()
        var history: [TimeInterval]

        enum Value {
            case count(Int)
            //            case int(Int)
            //            case double(Double)
        }
    }

    @ObservationIgnored
    var records: [String: Record] = [:]

    func _increment(counter key: String) {
        let now = Date.now.timeIntervalSinceReferenceDate
        if var record = records[key] {
            guard case let .count(original) = record.value else {
                fatalError("Tried to incremement a non-count value")
            }
            let count = original + 1
            record.value = .count(count)
            let last = record.last
            record.last = now
            record.lastInterval = now - last
            record.meanInterval = (record.last - record.first) / Double(count)
            record.movingAverageInterval.update(time: now - record.first, value: now - last)
            record.history = Array((record.history + [now]).drop { time in
                now - time > 10
            })
            records[key] = record
        }
        else {
            records[key] = Record(id: key, value: .count(0), first: now, last: now, history: [now])
        }
    }

    nonisolated
    public func increment(counter key: String) {
        Task {
            await _increment(counter: key)
        }
    }
}
