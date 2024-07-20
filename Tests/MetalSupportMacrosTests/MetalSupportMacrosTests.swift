import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MetalSupportMacros)
import MetalSupportMacros

let testMacros: [String: Macro.Type] = [
    "MetalBindings": MetalBindingsMacro.self,
    "MetalBinding": MetalBindingMacro.self,
    "MetalBindingIgnored": MetalBindingIgnoredMacro.self,
]
#endif

final class MetalBindingsMacrosTests: XCTestCase {
    func testMacro() throws {
        #if canImport(MetalSupportMacros)
        assertMacroExpansion(#"""
            @MetalBindings
            struct Bindings {
                var color: Int

                @MetalBindingIgnored
                var name: String

                @MetalBinding(function: .fragment)
                var exampleFragmentBinding: Int

                @MetalBinding(name: "newName")
                var oldName: Int
            }
            """#,
            expandedSource: #"""
            struct Bindings {
                var color: Int
                var name: String
                var exampleFragmentBinding: Int
                var oldName: Int
            }

            extension Bindings: MetalBindable {
                let bindingMappings: [(String, MTLFunctionType?, WritableKeyPath<Self, Int>)] = [
                    ("color", nil, \.color),
                    ("exampleFragmentBinding", .fragment, \.exampleFragmentBinding),
                    ("newName", nil, \.oldName)
                ]
            }
            """#,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
