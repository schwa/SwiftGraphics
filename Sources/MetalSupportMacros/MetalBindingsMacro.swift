import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum MetalBindingsMacro {
}

extension MetalBindingsMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        var defaultFunction: String?
        if let arguments = node.arguments, case let .argumentList(arguments) = arguments {
            defaultFunction = arguments.first { $0.label?.trimmedDescription == "function" }?.expression.trimmedDescription
        }
        // This is not a great way to detect if a declaration is public. Be nice to create a helper function that does it properly.
        let isPublic = declaration.modifiers.map(\.trimmedDescription).contains("public")
        // Get all variables within this declaration...
        let bindings: [(name: String, keyPath: String, type: String)] = declaration.match(path: [
            MemberBlockSyntax.self,
            MemberBlockItemListSyntax.self,
            MemberBlockItemSyntax.self,
            VariableDeclSyntax.self,
        ], viewMode: .sourceAccurate, as: VariableDeclSyntax.self)
        .compactMap {
            // Find all bindings of this variable...
            let patternBinding = $0.match(path: [
                PatternBindingListSyntax.self,
                PatternBindingSyntax.self,
            ], viewMode: .sourceAccurate, as: PatternBindingSyntax.self).first
            guard let patternBinding else {
                fatalError("Expected a pattern binding")
            }
            // Get the @ attributes of this property...
            let attributes = $0.attributes.compactMapAs(AttributeSyntax.self)
            // Skip any @MetalBindingIgnored we encounter...
            guard !attributes.contains(where: { $0.attributeName.trimmedDescription == "MetalBindingIgnored" }) else {
                return nil
            }
            // Get the variable name...
            let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmedDescription
            guard let identifier else {
                fatalError("Expected an identifier.")
            }
            // If we have a @MetalBinding we can use it to optionally override name and type
            let binding = attributes.first { $0.attributeName.trimmedDescription == "MetalBinding" }
            guard let binding, let arguments = binding.arguments, case let .argumentList(arguments) = arguments else {
                return ("\"\(identifier)\"", identifier, defaultFunction ?? "nil")
            }
            // Get (optional) name parameter and (optional) function type parameter...
            let name = arguments.first { $0.label?.trimmedDescription == "name" }?.expression.trimmedDescription
            let function = arguments.first { $0.label?.trimmedDescription == "function" }?.expression.trimmedDescription
            return (name ?? "\"\(identifier)\"", identifier, function ?? defaultFunction ?? "nil")
        }
        let mappings = bindings.map { name, identifier, type in
            "(\(name), \(type), \\.\(identifier))"
        }
        return [
            try ExtensionDeclSyntax(
                """
            extension \(type): MetalBindable {
                \(raw: isPublic ? "public " : "")nonisolated(unsafe) static let bindingMappings: [(String, MTLFunctionType?, WritableKeyPath<Self, Int>)] = [
                    \(raw: mappings.joined(separator: ",\n"))
                ]
            }
            """
            )
        ]
    }
}

// MARK: -

public enum MetalBindingMacro {
}

extension MetalBindingMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        // This macro is merely used to strip out @MetalBinding, most of the interesting work happens in MetalBindingsMacro
        []
    }
}

// MARK: -

public enum MetalBindingIgnoredMacro {
}

extension MetalBindingIgnoredMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        // This macro is merely used to strip out @MetalBindingIgnored, most of the interesting work happens in MetalBindingsMacro
        []
    }
}
