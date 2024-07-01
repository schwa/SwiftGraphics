//
//  Untitled.swift
//
//
//  Created by Jonathan Wight on 6/21/24.
//

import SwiftUI

import Fields3D

struct BallConstraintEditor: View {
    @Binding
    var ballConstraint: BallConstraint

    var body: some View {
        TextField("Radius", value: $ballConstraint.radius, format: .number)
//        TextField("Look AT", value: $ballConstraint.lookAt, format: .vector)
        RollPitchYawEditor($ballConstraint.rollPitchYaw)
    }
}
