import Metal
import MetalSupport
import Testing

@MetalBindings
struct Bindings {
    var property1: Int

    @MetalBinding(name: "binding2")
    var property2: Int

    @MetalBinding(function: .fragment)
    var property3: Int

    @MetalBindingIgnored
    var property4: Int
}

@Test
func test1() {
    let mappings = Bindings.bindingMappings
    #expect(mappings.count == 3)
    #expect(mappings[0].0 == "property1")
    #expect(mappings[0].1 == nil)
    #expect(mappings[0].2 == \.property1)

    #expect(mappings[1].0 == "binding2")
    #expect(mappings[1].1 == nil)
    #expect(mappings[1].2 == \.property2)

    #expect(mappings[2].0 == "property3")
    #expect(mappings[2].1 == .fragment)
    #expect(mappings[2].2 == \.property3)
}
