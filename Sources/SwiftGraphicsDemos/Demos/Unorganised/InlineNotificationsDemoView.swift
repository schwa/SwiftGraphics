import SwiftUI

struct InlineNotificationsDemoView: DemoView {
    @Environment(\.inlineNotificationsManager)
    var inlineNotificationsManager

    @State
    var n = 0

    var body: some View {
        Button("Post") {
            inlineNotificationsManager.post(.init(title: "hello world #\(n)", message: "hello world again", image: .init(systemName: "gear")))
            n += 1
        }
        .onAppear {
            inlineNotificationsManager.post(.init(title: "hello world", message: "hello world again", image: .init(systemName: "gear")))
        }
    }
}
