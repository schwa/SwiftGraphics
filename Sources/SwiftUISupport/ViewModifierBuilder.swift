import SwiftUI

@MainActor
@resultBuilder
public enum ViewModifierBuilder {
    public static func buildExpression<Content>(_ content: Content) -> Content where Content: ViewModifier {
        content
    }

    public static func buildBlock() -> EmptyViewModifier {
        EmptyViewModifier()
    }

    public static func buildBlock<Content>(_ content: Content) -> Content where Content: ViewModifier {
        content
    }

    public static func buildEither<TrueContent, FalseContent>(first: TrueContent) -> ConditionalViewModifier<TrueContent, FalseContent> where TrueContent: ViewModifier, FalseContent: ViewModifier {
        .init(trueModifier: first)
    }

    public static func buildEither<TrueContent, FalseContent>(second: FalseContent) -> ConditionalViewModifier<TrueContent, FalseContent> where TrueContent: ViewModifier, FalseContent: ViewModifier {
        .init(falseModifier: second)
    }
}

public struct ConditionalViewModifier<TrueModifier, FalseModifier>: ViewModifier where TrueModifier: ViewModifier, FalseModifier: ViewModifier {
    public var trueModifier: TrueModifier?
    public var falseModifier: FalseModifier?

    public init(trueModifier: TrueModifier) {
        self.trueModifier = trueModifier
    }

    public init(falseModifier: FalseModifier) {
        self.falseModifier = falseModifier
    }

    public func body(content: Content) -> some View {
        if let trueModifier {
            content.modifier(trueModifier)
        }
        else if let falseModifier {
            content.modifier(falseModifier)
        }
        else {
            fatalError("Either trueModifier or falseModifier must be non-nil.")
        }
    }
}
