# RenderKit

Yet another Metal Rendering engine experiment…

## Assumptions

Post-multiplication, Column-Major, Right-handed, Y up

## Screenshots

![Latest Screenshot](<Documentation/Screenshot 2023-09-19 at 19.51.00.png>)
![Older Screenshot](<Documentation/Screenshot 2023-07-01 at 08.06.29.png>)

## Goals

### Longer Term

* Tie into WASD/Game Controller system (from RenderKit - move code to Everything)
* Render the position of lights
* Learn from [RenderKit2](https://github.com/schwa/RenderKit/tree/RenderKit2) & [RenderKitClassic](https://github.com/schwa/RenderKit/tree/RenderKitClassic)
* More type-safety. Especially pipeline attributes
* Async. (Good luck)
* Outputs
  * A unified "renderable" system. Can render to any of multiple locations - MTKView, "raw" CAMetalLayer, offscreen textures, VistionKit immersive spaces etc.
  * ~~Built-in offscreen renderer~~ (Working but API can be fixed)
  * Built-in support for ~~MTKView~~ and CAMetalLayer
  * VisionKit 'CPSceneSessionRoleImmersiveSpaceApplication' output
  * (The more outputs the less fragile the APO will be)
* Simpler API for just getting shit on-screen
  * Create a simple render API that takes a single pipeline
* RenderEnvironment variables modelled after SwiftUI.Environment for safety
* Use Function-builder for pipelines/stages etc
* Cleaner render model that more closely matches Metal.
* Built-in support for RenderGraph editor (use NodeEditor)
* Work with multi-sample, ray tracing
* Figure out how to #include metal headers across packages (likely not possible).
* Get more helper code of RenderKit and into MetalSupport etc
* Use Spatial framework
  * Use the shape code from Spatial to bring in a `shape3d` type that can export MTKMeshes* Simple SwiftUI Canvas style line drawing mode.
  * Some of the rotation code here may be useful - what else is new in Spatial?
* Bring over my Projection package (3d vector graphics)
* Take advantage of Swift macros (macro to encode struct into a buffer compatible with SwiftUI)
* Sort out the various projection APIs

## Links

* <http://www.faqs.org/faqs/graphics/algorithms-faq/>
