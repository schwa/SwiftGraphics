import SwiftUI

public struct AnimatableValueView <Value, Content>: View, Animatable where Content: View, Value: VectorArithmetic & Sendable {
    public var animatableData: Value

    var content: (Value) -> Content

    public init(value: Value, content: @escaping (Value) -> Content) {
        self.animatableData = value
        self.content = content
    }

    public var body: some View {
        content(animatableData)
    }
}
