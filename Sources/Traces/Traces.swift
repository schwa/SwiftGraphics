import AsyncAlgorithms
import BaseSupport
import SwiftUI

public actor Traces {
    public static let shared = Traces()

    public struct Timestamp: Hashable, Sendable {
        var date: Date

        init() {
            date = .init()
        }
    }

    public struct Event: Hashable, Sendable {
        public var timestamp: Timestamp
        public var name: String

        var date: Date {
            timestamp.date
        }
    }

    var startTimestamp = Timestamp()
    var events: [Event] = []

    public nonisolated func trace(name: String, timestamp: Timestamp? = nil) {
        Task {
            await traceIsolated(name: name, timestamp: timestamp)
        }
    }

    private func traceIsolated(name: String, timestamp: Timestamp? = nil) {
        let timestamp = timestamp ?? .init()
        events.append(.init(timestamp: timestamp, name: name))
    }

    internal func popEvents(to date: Date) -> [Event] {
        events.sort()
        guard let index = events.lastIndex(where: { $0.date <= date }) else {
            return []
        }
        let result = events[...index]
        events.removeSubrange(...index)
        return Array(result)
    }
}

// MARK: -

public extension EnvironmentValues {
    @Entry
    var traces: Traces?
}

extension Traces.Event: Comparable {
    public static func < (lhs: Traces.Event, rhs: Traces.Event) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}

extension Traces.Timestamp: Comparable {
    public static func < (lhs: Traces.Timestamp, rhs: Traces.Timestamp) -> Bool {
        lhs.date < rhs.date
    }
}

// MARK: -

public struct TracesView: View {
    private var traces: Traces

    @State
    private var startDate = Date()

    @State
    private var currentEvents: [Traces.Event] = []

    @State
    private var size: CGSize = .init(width: 0, height: 0)

    private let pixelsPerSecond: CGFloat = 240

    private struct Stream {
        static let colors: [Color] = [.red, .green, .blue, .yellow, .purple, .orange]
        var name: String
        var index: Int
        var highFrequency: Bool = false
        var color: Color {
            Self.colors[index]
        }
    }

    @State
    private var streams: [String: Stream] = [:]

    public init(traces: Traces) {
        self.traces = traces
    }

    @ViewBuilder
    func labels(currentTime: Date) -> some View {
        Canvas { context, size in
            // Calculate elapsed time since start
            let elapsedTime = currentTime.timeIntervalSince(startDate)

            // Time interval between markers (in seconds)
            let markerInterval: TimeInterval = 1
            // Calculate horizontal offset based on elapsed time
            let offsetX = elapsedTime * Double(pixelsPerSecond)

            // Draw time markers
            let totalMarkers = Int((size.width + CGFloat(offsetX)) / (pixelsPerSecond * CGFloat(markerInterval)))
            for i in 0...totalMarkers {
                let markerTime = Double(i) * markerInterval
                let markerX = size.width - CGFloat(offsetX) + CGFloat(markerTime) * pixelsPerSecond
                if markerX >= 0 && markerX <= size.width {
                    context.stroke(Path { path in
                        path.move(to: CGPoint(x: markerX, y: 0))
                        path.addLine(to: CGPoint(x: markerX, y: 10))
                    }, with: .color(.gray), lineWidth: 1)
                    let text = Text(markerTime, format: .number).font(.caption)
                    context.draw(text, at: CGPoint(x: markerX, y: 20), anchor: .center)
                }
            }
        }
        .frame(height: 16)
    }

    @ViewBuilder
    private func timeline(stream: Stream, currentTime: Date) -> some View {
        Canvas { context, size in
            let markerSize: CGFloat = 10
            // Draw events
            for event in currentEvents where event.name == stream.name {
                let timeDifference = currentTime.timeIntervalSince(event.date)
                let x = round(size.width - CGFloat(timeDifference) * pixelsPerSecond)
                if x >= 0 {
                    if stream.highFrequency {
                        let path = Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: markerSize))
                        }
                        context.stroke(path, with: .color(stream.color), lineWidth: 1)
                    }
                    else {
                        let rect = CGRect(x: x - markerSize / 2, y: markerSize / 2, width: markerSize, height: markerSize)
                        context.fill(Path(ellipseIn: rect), with: .color(stream.color))
                    }
                }
            }
        }
        .frame(height: 16)
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            Grid(alignment: .topTrailing) {
                GridRow {
                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    labels(currentTime: timeline.date)
                        .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
                }
                ForEach(Array(streams.values), id: \.name) { stream in
                    GridRow {
                        Text(stream.name)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding([.leading, .trailing], 4)
                            .padding([.top, .bottom], 2)
                            .background(Capsule().fill(stream.color.gradient))
                        self.timeline(stream: stream, currentTime: timeline.date)
                    }
                }
            }
            .task(id: timeline.date) {
                await update(date: timeline.date)
            }
        }
    }

    func update(date: Date) async {
        assert(size.width != 0)
        let newEvents = await self.traces.popEvents(to: date)
        guard !newEvents.isEmpty else {
            return
        }
        insert(events: newEvents)
        // Remove events that have fallen off the left side
        let maxTimeDifference = Double(size.width / pixelsPerSecond)
        currentEvents.removeAll { event in
            let timeDifference = date.timeIntervalSince(event.date)
            return timeDifference > maxTimeDifference
        }
    }

    func insert(events: [Traces.Event]) {
        currentEvents.append(contentsOf: events)
        for name in Set(events.map(\.name)) where streams[name] == nil {
            streams[name] = .init(name: name, index: streams.count)
        }
    }
}

#Preview {
    TracesView(traces: .shared)
        .background(Color.white)
        .frame(width: 640, height: 480)
        .task {
            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(Double.random(in: 0...0.25)))
                Traces.shared.trace(name: "B")
            }
        }
        .task {
            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(Double.random(in: 0...0.5)))
                Traces.shared.trace(name: "C")
            }
        }

    Button("Trace") {
        Task {
            print("ISNERT")
            Traces.shared.trace(name: "D")
        }
    }
}
