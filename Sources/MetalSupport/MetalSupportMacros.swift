@attached(extension, conformances: MetalBindable)
@attached(memberAttribute)
public macro MetalBindings() = #externalMacro(module: "MetalSupportMacros", type: "MetalBindingsMacro")

@attached(peer)
public macro MetalBinding() = #externalMacro(module: "MetalSupportMacros", type: "MetalBindingMacro")

@attached(peer)
public macro MetalBindingIgnored() = #externalMacro(module: "MetalSupportMacros", type: "MetalBindingIgnoredMacro")
