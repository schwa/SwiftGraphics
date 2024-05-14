import Foundation
import SwiftUI

protocol DefaultInitializable {
    init()
}

protocol DefaultInitializableView: DefaultInitializable, View {
}
