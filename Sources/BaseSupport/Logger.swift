//
//  File.swift
//  SwiftGraphics
//
//  Created by Jonathan Wight on 7/16/24.
//

import Foundation
import os
import SwiftUI

public extension EnvironmentValues {
    @Entry
    var logger: Logger?
}

public extension View {
    // TOOD: .init() FIXME
    func logger(_ logger: Logger = .init()) -> some View {
        environment(\.logger, logger)
    }
}
