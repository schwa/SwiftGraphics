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

public struct InlineNotificationsView: View {
    @Environment(\.inlineNotificationsManager)
    private var inlineNotificationsManager

    @State
    private var visibleNotifications: [InlineNotification] = []

    @State
    private var repeatCounts: [InlineNotification.Payload: Int] = [:]

    public let limit = 3
    public let lifespan: TimeInterval = 10.0

    public var body: some View {
        VStack(spacing: 2) {
            ForEach(visibleNotifications) { notification in
                InlineNotificationView(notification: notification, repeatCount: repeatCounts[notification.payload] ?? 0) { notification in
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
        .onChange(of: inlineNotificationsManager.notifications, initial: true) {
            Task {
                await consume()
            }
        }
    }

    private func consume() async {
        inlineNotificationsManager.consume { newNotifications in
            outerloop:
            for newNotification in newNotifications {
                for (index, visibleNotification) in visibleNotifications.enumerated() where newNotification.payload == visibleNotification.payload {
                    repeatCounts[newNotification.payload, default: 0] += 1
                    visibleNotifications[index].posted = newNotification.posted
                    newNotifications.remove(contentsOf: [newNotification])
                    continue outerloop
                }
                if visibleNotifications.count < limit {
                    newNotifications.remove(contentsOf: [newNotification])
                    withAnimation {
                        visibleNotifications.append(newNotification)
                    }
                    Task.delayed(byTimeInterval: lifespan) {
                        await prune()
                    }
                }
            }
        }
    }

    private func prune() {
        let expiredNotifications = visibleNotifications.filter { Date.now.timeIntervalSince($0.posted) >= lifespan }
        withAnimation {
            visibleNotifications.remove(contentsOf: expiredNotifications)
        }
    }
}

public extension EnvironmentValues {
    @Entry
    var inlineNotificationsManager: InlineNotificationsManager = .shared
}

public struct InlineNotification: Identifiable, Sendable, Equatable {
    public var id = UUID()
    public var posted: Date = .now
    public var title: String
    public var message: String?
    public var image: Image?

    public init(title: String, message: String? = nil, image: Image? = nil) {
        self.title = title
        self.message = message
        self.image = image
    }
}

extension InlineNotification {
    struct Payload: Hashable {
        var title: String
        var message: String?
    }

    var payload: Payload {
        .init(title: title, message: message)
    }
}

@Observable
public final class InlineNotificationsManager: @unchecked Sendable {
    public static let shared = InlineNotificationsManager()

    @MainActor
    private(set) var notifications: [InlineNotification] = []

    public init() {
    }

    nonisolated
    public func post(_ notification: InlineNotification) {
        MainActor.runTask {
            self.notifications.append(notification)
        }
    }

    @MainActor
    internal func consume(_ callback: (inout [InlineNotification]) -> Void) {
        callback(&notifications)
    }
}

struct InlineNotificationView: View {
    var notification: InlineNotification

    var repeatCount: Int
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
                        HStack(alignment: .firstTextBaseline) {
                            Text(notification.title).font(.headline)
                            if repeatCount > 1 {
                                Text("(repeated \(repeatCount) times)")
                            }
                        }
                        if let message = notification.message {
                            Text(message).font(.subheadline)
                        }
                    }
                    .textSelection(.enabled)
                    Spacer()
                    TimelineView(.periodic(from: notification.posted, by: onHover ? 1.0 : 5.0)) { _ in
                        let string = "\(notification.posted, format: .relative(presentation: .named))"
                        Text(string)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(.regularMaterial)
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
        .frame(maxWidth: 320)
        .onHover {
            onHover = $0
        }
    }
}

public extension View {
    func inlineNotificationOverlay() -> some View {
        overlay(alignment: .top) {
            InlineNotificationsView()
        }
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
    .inlineNotificationOverlay()
    .onAppear {
        inlineNotificationsManager.post(.init(title: "hello world", message: "hello world again", image: .init(systemName: "gear")))
    }
}
