import SwiftUI
import Foundation

public protocol DefaultInitializable {
    init()
}

public protocol DefaultInitializableView: DefaultInitializable, View {
}
