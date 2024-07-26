import Foundation
import os
import SwiftUI

public extension EnvironmentValues {
    @Entry
    var logger: Logger?
}

public extension View {
    func logger(_ logger: Logger = .init()) -> some View {
        environment(\.logger, logger)
    }
}
