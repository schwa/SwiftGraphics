import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct MetalSupportMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MetalBindingsMacro.self,
        MetalBindingMacro.self,
        MetalBindingIgnoredMacro.self
    ]
}
