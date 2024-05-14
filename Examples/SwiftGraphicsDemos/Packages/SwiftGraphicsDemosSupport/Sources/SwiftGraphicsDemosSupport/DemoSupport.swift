import Foundation
import SwiftUI

public protocol DefaultInitializable {
    init()
}

public protocol DefaultInitializableView: DefaultInitializable, View {
}
