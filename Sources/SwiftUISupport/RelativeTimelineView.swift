import SwiftUI

public struct RelativeTimelineView<Schedule, Content>: View where Schedule: TimelineSchedule, Content: View {
    let schedule: Schedule
    let content: (TimelineViewDefaultContext, TimeInterval) -> Content

    @State
    private var start: Date = .init()

    public init(schedule: Schedule, @ViewBuilder content: @escaping (TimelineViewDefaultContext, TimeInterval) -> Content, start: Date = Date()) {
        self.schedule = schedule
        self.content = content
        self.start = start
    }

    public var body: some View {
        TimelineView(schedule) { context in content(context, Date().timeIntervalSince(start)) }
    }
}
