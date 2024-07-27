import SwiftUI
import SwiftUISupport

struct SignedDistanceFieldsDemoView: View, DemoView {
    var body: some View {
        RelativeTimelineView(schedule: .animation) { _, time in
            let function = ShaderLibrary.bundle(.module).signed_distance_field
            let shader = function(.float(time), .color(.teal), .color(.black))
            return Rectangle().colorEffect(shader)
        }
        .border(Color.red)
    }
}
