// periphery:ignore:all

import Metal

@attached(extension, conformances: MetalBindable, names: named(bindingMappings))
public macro MetalBindings() = #externalMacro(module: "MetalSupportMacros", type: "MetalBindingsMacro")

@attached(peer)
public macro MetalBinding(name: String? = nil, function: MTLFunctionType? = nil) = #externalMacro(module: "MetalSupportMacros", type: "MetalBindingMacro")

@attached(peer)
public macro MetalBindingIgnored() = #externalMacro(module: "MetalSupportMacros", type: "MetalBindingIgnoredMacro")
