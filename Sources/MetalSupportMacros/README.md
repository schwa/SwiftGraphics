
```metal
[[fragment]]
float4 FragmentShader(
    FragmentIn in [[stage_in]],
    constant SimplePBRFragmentUniforms &weirdlyNamedUniforms [[buffer(0)]],
    constant Material& material [[buffer(1)]],
    constant Light& light [[buffer(2)]] {
        ...
    }
```

```swift
@MetalBindings
struct MyBindings {
    @MetalBindingIgnored
    var name: String

    @MetalBinding(name: "weirdlyNamedUniforms", function: .fragment)
    var uniforms: Int = -1

    @MetalBinding(name: "material")
    var testMaterial: Int = -1

    var light: Int = -1
}

var bindings = MyBindings(name: "My Bindings")
let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
bindings.updateBindings(with: reflection)
assert(bindings.uniforms != -1 && myMaterial.someInteger != -1 && light.myBinding != -1)
...
commandEncoder.setVertexBuffer(myUniformsBuffer, offset: 0, index: bindings.uniforms)
commandEncoder.setVertexBuffer(myMaterial, offset: 0, index: bindings.testMaterial)
commandEncoder.setVertexBuffer(myLight, offset: 0, index: bindings.light)
```
