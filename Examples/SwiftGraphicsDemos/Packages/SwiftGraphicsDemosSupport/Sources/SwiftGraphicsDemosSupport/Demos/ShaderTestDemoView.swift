import SwiftUI

struct ShaderTestDemoView: View, DemoView {
    var body: some View {
        RelativeTimelineView(schedule: .animation) { _, time in
            let function = ShaderLibrary.signed_distance_field_2
            let shader = function(.float(time), .color(.teal), .color(.black))
            return Rectangle().fill(shader)
        }
    }
}
