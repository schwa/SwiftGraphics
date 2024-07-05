import BaseSupport
import Everything
import Observation
import SwiftUI

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .scale.combined(with: .opacity))
        )
    }
}

struct InlineNotificationsView: View {
    @Environment(\.inlineNotificationsManager)
    private var inlineNotificationsManager

    @State
    private var visibleNotifications: [InlineNotification] = []

    let limit = 3

    var body: some View {
        VStack(spacing: 2) {
            ForEach(visibleNotifications) { notification in
                InlineNotificationView(notification: notification) { notification in
                    withAnimation {
                        visibleNotifications.remove(contentsOf: [notification])
                    }
                }
                .transition(.moveAndFade)
            }
        }
        .padding()
        .onChange(of: visibleNotifications, initial: true) {
            Task {
                await consume()
            }
        }
        .onChange(of: inlineNotificationsManager.notifications) {
            Task {
                await consume()
            }
        }
    }

    private func consume() async {
        let newNotifications = inlineNotificationsManager.consume(upto: limit - visibleNotifications.count)
        withAnimation {
            visibleNotifications.append(contentsOf: newNotifications)
        }
        _ = Task.delayed(byTimeInterval: 60) {
            MainActor.runTask {
                withAnimation {
                    visibleNotifications.remove(contentsOf: newNotifications)
                }
                Task {
                    await consume()
                }
            }
        }
    }
}

extension EnvironmentValues {
    @Entry
    var inlineNotificationsManager: InlineNotificationsManager = .init()
}

struct InlineNotification: Identifiable, Sendable, Equatable {
    var id = UUID()
    var posted: Date = .now
    var title: String
    var message: String?
    var image: Image?

    init(title: String, message: String? = nil, image: Image? = nil) {
        self.title = title
        self.message = message
        self.image = image
    }
}

@Observable
final class InlineNotificationsManager: @unchecked Sendable {
    @MainActor
    private(set) var notifications: [InlineNotification] = []

    init() {
    }

    nonisolated
    func post(_ notification: InlineNotification) {
        MainActor.runTask {
            self.notifications.append(notification)
        }
    }

    @MainActor
    func consume(upto count: Int) -> [InlineNotification] {
        let consumed = notifications.prefix(count)
        notifications = Array(notifications.dropFirst(count))
        return Array(consumed)
    }
}

#Preview {
    @Previewable @Environment(\.inlineNotificationsManager)
    var inlineNotificationsManager

    @Previewable @State
    var n = 0

    VStack {
        Color.white
        Button("Post") {
            inlineNotificationsManager.post(.init(title: "hello world #\(n)", message: "hello world again", image: .init(systemName: "gear")))
            n += 1
        }
    }
    .overlay(alignment: .top) {
        InlineNotificationsView()
    }
    .onAppear {
        inlineNotificationsManager.post(.init(title: "hello world", message: "hello world again", image: .init(systemName: "gear")))
    }
}

extension Task where Failure == Error {
    static func delayed(
        byTimeInterval delayInterval: TimeInterval,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            let delay = UInt64(delayInterval * 1_000_000_000)
            try await Task<Never, Never>.sleep(nanoseconds: delay)
            return try await operation()
        }
    }

    static func scheduled(at date: Date, priority: TaskPriority? = nil,
                          operation: @escaping @Sendable () async throws -> Success) async -> Task {
        let now = Date()
        return Task(priority: priority) {
            let interval = date.timeIntervalSince(now)
            await withCheckedContinuation { continuation in
                Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                    continuation.resume()
                }
            }
            return try await operation()
        }
    }
}

struct InlineNotificationView: View {
    var notification: InlineNotification

    var remove: (InlineNotification) -> Void

    @State
    private var onHover: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack {
                notification.image?
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxHeight: 32)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading) {
                        Text(notification.title).font(.headline)
                        if let message = notification.message {
                            Text(message).font(.subheadline)
                        }
                    }
                    Spacer()
                    TimelineView(.periodic(from: notification.posted, by: onHover ? 1.0 : 5.0)) { _ in
                        let string = "\(notification.posted, format: .relative(presentation: .named))"
                        Text(string)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(4)
            .background(.thickMaterial)
            .cornerRadius(8)
            .shadow(radius: 1)
            .padding([.top, .leading, .trailing], 4)

            if onHover {
                Button {
                    remove(notification)
                } label: {
                    Image(systemName: "x.circle")
                        .background(Circle().fill(.white))
                }
                .buttonStyle(.borderless)
            }
        }
        .onHover {
            onHover = $0
        }
    }
}
