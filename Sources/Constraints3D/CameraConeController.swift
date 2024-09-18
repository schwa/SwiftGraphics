// periphery:ignore:all

import simd
import SIMDSupport
import SwiftFields
import SwiftUI

public struct CameraConeController: ViewModifier {
    private var cameraConeConstraint: CameraConeConstraint

    @Binding
    var transform: Transform

    @State
    private var angle: Angle = .zero
    @State
    private var height: Double = 0.5

    public init(cameraCone: ConeBounds, transform: Binding<Transform>) {
        self.cameraConeConstraint = .init(cameraCone: cameraCone)
        self._transform = transform
    }

    public func body(content: Content) -> some View {
        content
            .draggableParameter($height, axis: .vertical, range: 0...1, scale: -0.02, behavior: .clamping)
            #if os(macOS)
            .draggableParameter($angle.degrees, axis: .horizontal, range: 0...360, scale: 0.1, behavior: .wrapping)
            #else
            .draggableParameter($angle.degrees, axis: .horizontal, range: 0...360, scale: -0.5, behavior: .wrapping)
            #endif
            .onChange(of: cameraConeConstraint, initial: true) {
                transform = .init(cameraConeConstraint.transform(angle: angle, height: height))
            }
            .onChange(of: angle, initial: true) {
                transform = .init(cameraConeConstraint.transform(angle: angle, height: height))
            }
            .onChange(of: height, initial: true) {
                transform = .init(cameraConeConstraint.transform(angle: angle, height: height))
            }
        #if os(macOS)
        .overlay(alignment: .bottom) {
        Form {
        TextField("Angle", value: $angle.degrees, format: .number.precision(.fractionLength(0...0)))
        Slider(value: $angle.degrees, in: 0...360)
        TextField("Height", value: $height, format: .number.precision(.fractionLength(0...3)))
        Slider(value: $height, in: 0...1)
        LabeledContent("LookAt", value: cameraConeConstraint.lookAt, format: .vector)
        LabeledContent("Bounds.Origin", value: cameraConeConstraint.cameraCone.origin, format: .vector)
        LabeledContent("Bounds.bottomHeight", value: cameraConeConstraint.cameraCone.bottomHeight, format: .number)
        LabeledContent("Bounds.bottomInnerRadius", value: cameraConeConstraint.cameraCone.bottomInnerRadius, format: .number)
        LabeledContent("Bounds.topHeight", value: cameraConeConstraint.cameraCone.topHeight, format: .number)
        LabeledContent("Bounds.topInnerRadius", value: cameraConeConstraint.cameraCone.topInnerRadius, format: .number)
        LabeledContent("Camera Position", value: cameraConeConstraint.cameraCone.position(h: Float(height), angle: angle), format: .vector)
        }
        .controlSize(.mini)
        .frame(maxWidth: 320)
        .padding()
        .background(.thinMaterial)
        .padding()
        }
        #endif
    }
}

// MARK: -

public struct CameraConeConstraint: Equatable {
    public var cameraCone: ConeBounds
    public var lookAt: SIMD3<Float>

    public init(cameraCone: ConeBounds, lookAt: SIMD3<Float> = .zero) {
        self.cameraCone = cameraCone
        self.lookAt = lookAt
    }

    func transform(angle: Angle, height: Double) -> simd_float4x4 {
        let position = cameraCone.position(h: Float(height), angle: angle)
        return look(at: lookAt, from: position, up: [0, 1, 0])
    }
}

/// Represents the bounds of a truncated cone/frustum. The origin.z is level with bottomHeight.
public struct ConeBounds {
    public var origin: SIMD3<Float>
    public var bottomHeight: Float
    public var bottomInnerRadius: Float
    public var topHeight: Float
    public var topInnerRadius: Float

    public init(origin: SIMD3<Float> = .zero, bottomHeight: Float, bottomInnerRadius: Float, topHeight: Float, topInnerRadius: Float) {
        self.origin = origin
        self.bottomHeight = bottomHeight
        self.bottomInnerRadius = bottomInnerRadius
        self.topHeight = topHeight
        self.topInnerRadius = topInnerRadius
    }
}

extension ConeBounds: Sendable {
}

extension ConeBounds: Equatable {
}

extension ConeBounds: Hashable {
}

public extension ConeBounds {
    func position(h: Float, angle: Angle, isVerticalScreen: Bool = true) -> SIMD3<Float> {
        // Since view is scaled based on height of screen we need to zoom out for vertical viewports
        let topInnerRadius = topInnerRadius * (isVerticalScreen ? 1.5 : 1.0)
        let radius = bottomInnerRadius + h * (topInnerRadius - bottomInnerRadius)
        let x = radius * Float(sin(angle.radians))
        let y = bottomHeight + h * (topHeight - bottomHeight)
        let z = radius * Float(cos(angle.radians))
        return origin + SIMD3<Float>(x, y, z)
    }
}
