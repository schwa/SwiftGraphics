//
//  BallController.swift
//  SwiftGraphics
//
//  Created by Jonathan Wight on 8/7/24.
//

import SIMDSupport
import SwiftUI

public struct NewBallControllerViewModifier: ViewModifier {
    @State
    private var constraint: NewBallConstraint

    @Binding var transform: Transform

    public init(constraint: NewBallConstraint, transform: Binding<Transform>) {
        self.constraint = constraint
        self._transform = transform
    }

    public func body(content: Content) -> some View {
        content
        .draggableParameter($constraint.pitch.degrees, axis: .vertical, range: 0...360, scale: 0.1, behavior: .clamping)
        .draggableParameter($constraint.yaw.degrees, axis: .horizontal, range: 0...360, scale: 0.1, behavior: .wrapping)
        .onChange(of: constraint.transform, initial: true) {
            transform = constraint.transform
        }
    }
}

// MARK: -

public struct NewBallConstraint: Equatable {
    public var transform: Transform {
        Transform(roll: .zero, pitch: pitch, yaw: yaw, translation: [0, 0, radius])
   }

    public var target: SIMD3<Float>
    public var radius: Float
    public var pitch: Angle
    public var yaw: Angle

    public init(target: SIMD3<Float> = .zero, pitch: Angle = .zero, yaw: Angle = .zero, radius: Float) {
        self.target = target
        self.radius = radius
        self.pitch = pitch
        self.yaw = yaw
    }
}
