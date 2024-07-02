/*

 PassProtocol.
 RenderPassProtocol
 RenderPassProtocol
 CompositePass

 public protocol PassProtocol: Identifiable {
 var id: AnyHashable { get }
 }

 public protocol XPassContext {
 }

 public protocol XRenderPassContext: XPassContext {
 }

 public protocol XRenderPassProtocol: PassProtocol {
 typealias Context = XRenderPassContext
 }

 struct CompositePass: PassProtocol {
 let id: AnyHashable

 let children: [any PassProtocol]

 init(id: AnyHashable, children: [any PassProtocol]) {
 self.id = id
 self.children = children
 }
 }
 */
