import BaseSupport
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import Metal
import MetalKit
import SIMDSupport
import SwiftUI
#if os(macOS)
import AppKit
#endif

import BaseSupport
import CoreGraphics
import CoreGraphicsSupport
import CoreGraphicsUnsafeConformances
import Everything
import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders
import MetalSupport
import ModelIO
import os
import Projection
import Shapes2D
import Shapes3D
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI
import UniformTypeIdentifiers

extension MTKMesh {
    /// Total length of all buffers in MTKMesh
    var totalLength: Int {
        let vertexBuffersLength = vertexBuffers.map(\.length).reduce(0, +)
        let submeshesIndexBuffersLength = submeshes.map(\.indexBuffer.length).reduce(0, +)
        return vertexBuffersLength + submeshesIndexBuffersLength
    }
}

extension SIMD3<Float> {
    func distance(to rhs: SIMD3<Float>) -> Float {
        (self - rhs).length
    }
}

// MARK: -

// MARK: -

// MARK: -

func hslToRgb(_ h: Float, _ s: Float, _ l: Float) -> (Float, Float, Float) {
    if s == 0 {
        return (1, 1, 1)
    } else {
        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q
        let r = hueToRgb(p, q, h + 1 / 3)
        let g = hueToRgb(p, q, h)
        let b = hueToRgb(p, q, h - 1 / 3)
        return (r, g, b)
    }
}

func hueToRgb(_ p: Float, _ q: Float, _ t: Float) -> Float {
    var t = t
    if t < 0 { t += 1 }
    if t > 1 { t -= 1 }
    if t < 1 / 6 {
        return p + (q - p) * 6 * t
    }
    if t < 1 / 2 {
        return q
    }
    if t < 2 / 3 {
        return p + (q - p) * (2 / 3 - t) * 6
    }
    return p
}

struct SpatialTapGestureModifier: ViewModifier {
    let callback: (CGPoint) -> Void

    @State
    var start: CGPoint?

    func body(content: Content) -> some View {
        content.gesture(DragGesture(minimumDistance: 0).onChanged { value in
            if start == nil {
                start = value.location
            }
        }
        .onEnded { value in
            callback(value.location)
        })
    }
}

extension View {
    func onSpatialTapGesture(_ callback: @escaping (CGPoint) -> Void) -> some View {
        modifier(SpatialTapGestureModifier(callback: callback))
    }
}

extension Image {
    init(url: URL) throws {
        if try url.checkResourceIsReachable() == false {
            throw BaseError.error(.inputOutputFailure)
        }
        #if os(macOS)
        guard let nsImage = NSImage(contentsOf: url) else {
            throw BaseError.error(.inputOutputFailure)
        }
        self = Image(nsImage: nsImage)
        #elseif os(iOS)
        guard let uiImage = UIImage(contentsOfFile: url.path) else {
            throw BaseError.error(.inputOutputFailure)
        }
        self = Image(uiImage: uiImage)
        #endif
    }
}

extension MemoryLayout {
    static func packedStride(of value: T) -> Int {
        switch value {
        case let value as SIMD3<Float>:
            return MemoryLayout<Float>.stride * value.scalarCount
        default:
            return stride
        }
    }
}

extension MTKTextureLoader {
    func newTexture(for color: CGColor, options: [MTKTextureLoader.Option: Any]? = nil) throws -> MTLTexture {
        let image = try color.makeImage()
        let texture = try newTexture(cgImage: image, options: options)
        texture.label = "CGColor(\(color))"
        return texture
    }
}

extension Path3D {
    init(box: Box3D) {
        self = Path3D { path in
            path.move(to: box.minXMinYMinZ)
            path.addLine(to: box.maxXMinYMinZ)
            path.addLine(to: box.maxXMaxYMinZ)
            path.addLine(to: box.minXMaxYMinZ)
            path.closePath()

            path.move(to: box.minXMinYMaxZ)
            path.addLine(to: box.maxXMinYMaxZ)
            path.addLine(to: box.maxXMaxYMaxZ)
            path.addLine(to: box.minXMaxYMaxZ)
            path.closePath()

            path.move(to: box.minXMinYMinZ)
            path.addLine(to: box.minXMinYMaxZ)

            path.move(to: box.maxXMinYMinZ)
            path.addLine(to: box.maxXMinYMaxZ)

            path.move(to: box.maxXMaxYMinZ)
            path.addLine(to: box.maxXMaxYMaxZ)

            path.move(to: box.minXMaxYMinZ)
            path.addLine(to: box.minXMaxYMaxZ)
        }
    }
}

public protocol UnsafeMemoryEquatable: Equatable {
}

// swiftlint:disable:next extension_access_modifier
extension UnsafeMemoryEquatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        withUnsafeBytes(of: lhs) { lhs in
            withUnsafeBytes(of: rhs) { rhs in
                guard lhs.count == rhs.count else {
                    return false
                }
                let count = lhs.count
                guard let lhs = lhs.baseAddress, let rhs = rhs.baseAddress else {
                    return true
                }
                return memcmp(lhs, rhs, count) == 0
            }
        }
    }
}

func max(lhs: SIMD3<Float>, rhs: SIMD3<Float>) -> SIMD3<Float> {
    [max(lhs[0], rhs[0]), max(lhs[1], rhs[1]), max(lhs[2], rhs[2])]
}

func min(lhs: SIMD3<Float>, rhs: SIMD3<Float>) -> SIMD3<Float> {
    [min(lhs[0], rhs[0]), min(lhs[1], rhs[1]), min(lhs[2], rhs[2])]
}

extension MTLComputeCommandEncoder {
    func setBytes(_ bytes: UnsafeRawBufferPointer, index: Int) {
        setBytes(bytes.baseAddress!, length: bytes.count, index: index)
    }

    func setBytes(of value: some Any, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            setBytes(buffer, index: index)
        }
    }

    func setBytes(of value: [some Any], index: Int) {
        value.withUnsafeBytes { buffer in
            setBytes(buffer, index: index)
        }
    }
}

// TODO: Deprecate - there's already an Axis3D
enum Axis3 {
    case x
    case y
    case z
}

extension Axis3 {
    var positiveVector: SIMD3<Float> {
        switch self {
        case .x:
            [1, 0, 0]
        case .y:
            [0, 1, 0]
        case .z:
            [0, 0, 1]
        }
    }
}

extension SIMD3<Float> {
    func angle(along axis: Axis3) -> Angle {
        // Project the vector onto the plane perpendicular to the axis
        let projectedVector: SIMD3<Float>
        switch axis {
        case .x:
            projectedVector = [0, self.y, self.z]
        case .y:
            projectedVector = [self.x, 0, self.z]
        case .z:
            projectedVector = [self.x, self.y, 0]
        }

        // Calculate the angle using atan2
        let angle: Float
        switch axis {
        case .x:
            angle = atan2(projectedVector.z, projectedVector.y)
        case .y:
            angle = atan2(projectedVector.x, projectedVector.z)
        case .z:
            angle = atan2(projectedVector.y, projectedVector.x)
        }

        // Convert to the desired Angle type
        return .radians(Double(angle))
    }
}

// TODO: Move
extension CGVector {
    init(_ dx: CGFloat, _ dy: CGFloat) {
        self = CGVector(dx: dx, dy: dy)
    }

    init(_ size: CGSize) {
        self = CGVector(dx: size.width, dy: size.height)
    }
}

extension SIMD3 where Scalar == Float {
    var h: Float {
        get {
            x
        }
        set {
            x = newValue
        }
    }

    var s: Float {
        get {
            y
        }
        set {
            y = newValue
        }
    }

    var v: Float {
        get {
            z
        }
        set {
            z = newValue
        }
    }

    func hsv2rgb() -> Self {
        let h_i = Int(h * 6)
        let f = h * 6 - Float(h_i)
        let p = v * (1 - s)
        let q = v * (1 - f * s)
        let t = v * (1 - (1 - f) * s)

        // swiftlint:disable switch_case_on_newline
        switch h_i {
        case 0: return [v, t, p]
        case 1: return [q, v, p]
        case 2: return [p, v, t]
        case 3: return [p, q, v]
        case 4: return [t, p, v]
        case 5: return [v, p, q]
        default: return [0, 0, 0]
        }
    }
}

extension Shapes2D.Circle {
    init(containing rect: CGRect) {
        let center = rect.midXMidY
        let diameter = sqrt(rect.width * rect.width + rect.height * rect.height)
        self = .init(center: center, diameter: diameter)
    }
}

extension Triangle {
    init(containing circle: Shapes2D.Circle) {
        let a = circle.center + CGPoint(length: circle.radius * 2, angle: Angle.degrees(0))
        let b = circle.center + CGPoint(length: circle.radius * 2, angle: Angle.degrees(120))
        let c = circle.center + CGPoint(length: circle.radius * 2, angle: Angle.degrees(240))
        self = .init(a, b, c)
    }
}

extension MTLDepthStencilDescriptor {
    static func always() -> MTLDepthStencilDescriptor {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .always
        descriptor.label = "always"
        return descriptor
    }
}

extension MTLRenderPipelineColorAttachmentDescriptor {
    func enableStandardAlphaBlending() {
        isBlendingEnabled = true
        rgbBlendOperation = .add
        alphaBlendOperation = .add
        sourceRGBBlendFactor = .sourceAlpha
        sourceAlphaBlendFactor = .sourceAlpha
        destinationRGBBlendFactor = .oneMinusSourceAlpha
        destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
}

struct ShowOnHoverModifier: ViewModifier {
    @State
    var hovering = false

    func body(content: Content) -> some View {
        ZStack {
            Color.clear
            content.opacity(hovering ? 1 : 0)
        }
        .onHover { hovering in
            self.hovering = hovering
        }
    }
}

extension View {
    func showOnHover() -> some View {
        modifier(ShowOnHoverModifier())
    }
}

extension YAMesh {
    static func simpleMesh(label: String? = nil, primitiveType: MTLPrimitiveType = .triangle, device: MTLDevice, content: () -> ([UInt16], [SimpleVertex])) throws -> YAMesh {
        let (indices, vertices) = content()
        return try simpleMesh(label: label, indices: indices, vertices: vertices, primitiveType: primitiveType, device: device)
    }
}

private final class PrintOnceManager {
    nonisolated(unsafe) static let instance = PrintOnceManager()

    //    var printedAlready = OSAllocatedUnfairLock(uncheckedState: [Set<String>]())

    var printedAlready: Set<String> = []

    func printedAlready(_ s: String) -> Bool {
        if printedAlready.contains(s) {
            return true
        }
        printedAlready.insert(s)
        return false
    }
}

func printOnce(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    var s = ""
    print(items, separator: separator, terminator: terminator, to: &s)
    guard PrintOnceManager.instance.printedAlready(s) == false else {
        return
    }
    print(s, terminator: "")
}

#if os(macOS)
struct LastRightMouseDownLocationModifier: ViewModifier {
    @Binding
    var location: CGPoint?

    var coordinateSpace: CoordinateSpace

    init(_ location: Binding<CGPoint?>, coordinateSpace: CoordinateSpace = .local) {
        _location = location
        self.coordinateSpace = coordinateSpace
    }

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content.onAppear {
                NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) { event in
                    if let frame = event.window?.frame {
                        let windowLocation = event.locationInWindow.flipVertically(within: frame)
                        let localWindowFrame = geometry.frame(in: coordinateSpace)
                        location = windowLocation - localWindowFrame.origin
                    }
                    return event
                }
            }
        }
    }
}

extension View {
    func lastRightMouseDownLocation(_ location: Binding<CGPoint?>, coordinateSpace: CoordinateSpace = .local) -> some View {
        modifier(LastRightMouseDownLocationModifier(location, coordinateSpace: coordinateSpace))
    }
}
#endif

// MARK: -

struct Composite<Root, Stem> {
    var root: Root
    var stem: Stem?

    init(_ root: Root, _ stem: Stem? = nil) {
        self.root = root
        self.stem = stem
    }
}

extension Composite: Equatable where Root: Equatable, Stem: Equatable {
}

extension Composite: Hashable where Root: Hashable, Stem: Hashable {
}

// MARK: -

struct EmptyShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path()
    }
}

// MARK: -

// MARK: -

struct JSONCodingTransferable<Element>: Transferable where Element: Codable {
    let element: Element

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .json) { layer in
            try JSONEncoder().encode(layer.element)
        } importing: { data in
            let element = try JSONDecoder().decode(Element.self, from: data)
            return Self(element: element)
        }
    }
}

// MARK: -

// MARK: -

extension GraphicsContext {
    func drawDot(at position: CGPoint) {
        fill(Path.circle(center: position, radius: 2), with: .color(.black))
    }
}

extension Array {
    func get(index: Index) -> Element? {
        if (startIndex ..< endIndex).contains(index) {
            self[index]
        } else {
            nil
        }
    }
}

extension Sequence {
    var tuple2: (Element, Element) {
        let array = Array(self)
        assert(array.count == 2)
        return (array[0], array[1])
    }

    var tuple3: (Element, Element, Element) {
        let array = Array(self)
        assert(array.count == 3)
        return (array[0], array[1], array[2])
    }
}

struct PeekingWindowIterator<I>: IteratorProtocol where I: IteratorProtocol {
    typealias Element = (previous: I.Element?, current: I.Element, next: I.Element?)

    var iterator: I
    var element: Element?

    init(iterator: I) {
        self.iterator = iterator
    }

    mutating func next() -> Element? {
        if element == nil {
            guard let current = iterator.next() else {
                return nil
            }
            let next = iterator.next()
            element = (previous: nil, current: current, next: next)
            return element
        } else {
            guard let previous = element else {
                fatalError("No previous element.")
            }
            guard let next = previous.next else {
                return nil
            }
            element = (previous: previous.current, current: next, next: iterator.next())
            return element
        }
    }
}

extension Sequence {
    func peekingWindow() -> PeekingWindowIterator<Iterator> {
        PeekingWindowIterator(iterator: makeIterator())
    }
}

extension GraphicsContext {
    mutating func translateBy(_ size: CGSize) {
        translateBy(x: size.width, y: size.height)
    }
}

extension Dictionary where Value: Identifiable, Key == Value.ID {
    func contains(_ value: Value) -> Bool {
        self[value.id] != nil
    }

    @discardableResult
    mutating func insert(_ newMember: Value) -> (inserted: Bool, memberAfterInsert: Value) {
        if let oldMember = self[newMember.id] {
            return (false, oldMember)
        } else {
            self[newMember.id] = newMember
            return (true, newMember)
        }
    }

    @discardableResult
    mutating func update(with newMember: Value) -> Value? {
        let oldValue = self[newMember.id]
        self[newMember.id] = newMember
        return oldValue
    }

    @discardableResult
    mutating func remove(_ member: Value) -> Value? {
        let oldValue = self[member.id]
        self[member.id] = nil
        return oldValue
    }
}

struct MarkingsView: View {
    enum Guide {
        case line(Line)
        case point(CGPoint)
        //        case circle
        //        case
    }

    let guides = [
        Self.rulerGuides(width: 20, angle: .zero)
    ]

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(size: size)
            for guide in guides {
                let guides = guide(.zero, bounds)
                for guide in guides {
                    switch guide {
                    case .line(let line):
                        if let segment = line.lineSegment(bounds: bounds) {
                            let path = Path.line(from: segment.start, to: segment.end)
                            context.stroke(path, with: .color(Color.black), lineWidth: 1 / 4)
                        }
                    default:
                        BaseSupport.unimplemented()
                    }
                }
            }
        }
    }

    static func rulerGuides(width: Double, angle: Angle, includeZero: Bool = true) -> (_ origin: CGPoint, _ bounds: CGRect) -> [Guide] {
        { _, bounds in
            let d = CGPoint(bounds.size).length
            return stride(from: includeZero ? 0 : width, through: d, by: width).map { Guide.line(.vertical(x: $0)) }
        }
    }
}

extension GraphicsContext {
    func drawMarkers(at positions: [CGPoint], size: CGSize) {
        for position in positions {
            let image = Image(systemName: "circle.fill")
            draw(image, in: CGRect(center: position, size: size))
        }
    }
}

extension Binding where Value == CGPoint {
    func transformed(_ transform: CGAffineTransform) -> Binding {
        let inverse = transform.inverted()
        return Binding {
            wrappedValue.applying(transform)
        } set: { newValue in
            wrappedValue = newValue.applying(inverse)
        }
    }

    func transformed(_ modify: @escaping @Sendable (CGFloat) -> CGFloat) -> Binding {
        Binding {
            wrappedValue
        } set: { newValue in
            wrappedValue = newValue.map(modify)
        }
    }
}

extension GraphicsContext {
    func stroke(_ path: Path, with shading: GraphicsContext.Shading, lineWidth: CGFloat = 1, transform: CGAffineTransform) {
        let path = path.applying(transform)
        stroke(path, with: shading, lineWidth: lineWidth)
    }

    func fill(_ path: Path, with shading: GraphicsContext.Shading, transform: CGAffineTransform) {
        let path = path.applying(transform)
        fill(path, with: shading)
    }
}

extension Color: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let components = try container.decode([Double].self)
        self = .init(red: components[0], green: components[1], blue: components[2])
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let components = resolve(in: .init()).cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?.components else {
            throw BaseError.error(.parsingFailure)
        }
        try container.encode(components)
    }
}

@propertyWrapper
struct CodableAppStorage<Value>: DynamicProperty, Sendable where Value: Codable & Sendable {
    var key: String

    @State
    var storage: Value

    var wrappedValue: Value {
        get {
            storage
        }
        nonmutating set {
            do {
                storage = newValue
                let data = try JSONEncoder().encode(newValue)
                let string = String(decoding: data, as: UTF8.self)
                UserDefaults.standard.setValue(string, forKey: key)
            } catch {
                fatalError(error)
            }
        }
    }

    init(wrappedValue: Value, _ key: String) {
        do {
            self.key = key
            if let string = UserDefaults.standard.string(forKey: key) {
                let data = string.data(using: .utf8)!
                let value = try JSONDecoder().decode(Value.self, from: data)
                _storage = .init(initialValue: value)
            } else {
                _storage = .init(initialValue: wrappedValue)
            }
        } catch {
            fatalError(error)
        }
    }

    var projectedValue: Binding<Value> {
        Binding<Value> {
            wrappedValue
        }
        set: { newValue in
            wrappedValue = newValue
        }
    }
}

extension CodableAppStorage where Value: ExpressibleByNilLiteral {
    init(_ key: String) {
        do {
            self.key = key
            if let string = UserDefaults.standard.string(forKey: key) {
                let data = string.data(using: .utf8)!
                let value = try JSONDecoder().decode(Value.self, from: data)
                _storage = .init(initialValue: value)
            } else {
                _storage = .init(initialValue: nil)
            }
        } catch {
            fatalError(error)
        }
    }
}

extension LineSegment {
    var angle: Angle {
        (Angle(from: start, to: end) + .degrees(360 + 90)).truncatingRemainder(dividingBy: .degrees(360))
    }

    var inverted: LineSegment {
        .init(end, start)
    }
}

extension Collection {
    subscript(offset offset: Int) -> Element {
        self[index(startIndex, offsetBy: offset)]
    }
}

extension Int {
    var isEven: Bool {
        self.isMultiple(of: 2)
    }
}

extension View {
    func onDragGesture(onChanged: @escaping (DragGesture.Value) -> Void, onEnded: @escaping (DragGesture.Value) -> Void) -> some View {
        gesture(DragGesture().onChanged(onChanged).onEnded(onEnded))
    }
}

extension Array {
    subscript(relative index: Int) -> Element {
        get {
            if index >= 0 {
                self[index]
            } else {
                self[count + index]
            }
        }
        set {
            if index >= 0 {
                self[index] = newValue
            } else {
                self[count + index] = newValue
            }
        }
    }
}

extension View {
    func onSpatialTap(count: Int = 1, coordinateSpace: some CoordinateSpaceProtocol = .local, handler: @escaping (CGPoint) -> Void) -> some View {
        gesture(SpatialTapGesture(count: count, coordinateSpace: coordinateSpace).onEnded { value in
            handler(value.location)
        })
    }
}

struct RasterizerOptionsView: View {
    @Binding
    var options: Rasterizer.Options

    var body: some View {
        // Toggle("Axis Rules", isOn: options.contains(.showAxisRules))
        Toggle("Draw Polygon Normals", isOn: $options.drawNormals)
        TextField("Normals Length", value: $options.normalsLength, format: .number)
        Toggle("Shade Normals", isOn: $options.shadeFragmentsWithNormals)
        Toggle("Backface Culling", isOn: $options.backfaceCulling)
    }
}

extension View {
    func inspector <Content>(@ViewBuilder content: @escaping () -> Content) -> some View where Content: View {
        ValueView(value: true) { isPresented in
            inspector(isPresented: isPresented) {
                content().toolbar {
                    Spacer()
                    Toggle(isOn: isPresented) { Label("Inspector", systemImage: "sidebar.right") }
                        .toggleStyle(.button)
                }
            }
        }
    }
}

extension Path {
    static func arrow(start: CGPoint, end: CGPoint, startStyle: ArrowHeadStyle? = nil, endStyle: ArrowHeadStyle = .simple) -> Path {
        Path { path in
            path.move(to: start)
            path.addLine(to: end)
            let angle = Angle(from: start, to: end)
            path.addPath(arrowHead(style: endStyle), transform: .rotation(angle) * .translation(end))
        }
    }

    enum ArrowHeadStyle {
        case simple
        case simpleHalfLeft
        case simpleHalfRight
    }

    static func arrowHead(size: Double = 5, style: ArrowHeadStyle = .simple) -> Path {
        Path { path in
            switch style {
            case .simple:
                path.move(to: [-size, -size])
                path.addLine(to: .zero)
                path.move(to: [-size, size])
                path.addLine(to: .zero)
            case .simpleHalfLeft:
                path.move(to: [-size, -size])
                path.addLine(to: .zero)
            case .simpleHalfRight:
                path.move(to: [-size, size])
                path.addLine(to: .zero)
            }
        }
    }
}

extension MDLMeshConvertable {
    func toYAMesh(allocator: MDLMeshBufferAllocator?, device: MTLDevice) throws -> YAMesh {
        let mdlMesh = try toMDLMesh(allocator: allocator)
        return try YAMesh(label: "\(type(of: self))", mdlMesh: mdlMesh, device: device)
    }
}

extension Path3D {
    init(path: Path) {
        let elements = path.elements
        self = Path3D { path in
            for element in elements {
                switch element {
                case .move(let point):
                    path.move(to: SIMD3(xy: SIMD2(point)))
                case .line(let point):
                    path.addLine(to: SIMD3(xy: SIMD2(point)))
                case .closeSubpath:
                    path.closePath()
                default:
                    BaseSupport.unimplemented()
                }
            }
        }
    }
}

extension UTType {
    static let plyFile = UTType(importedAs: "public.polygon-file-format")
}

extension Bundle {
    func url(forResource resource: String?, withExtension extension: String?) throws -> URL {
        guard let url = url(forResource: resource, withExtension: `extension`) else {
            throw BaseError.error(.resourceCreationFailure)
        }
        return url
    }
}

extension Bundle {
    static func bundle(forProject project: String, target: String) -> Bundle? {
        let url = Bundle.main.url(forResource: "\(project)_\(target)", withExtension: "bundle")!
        return Bundle(url: url)
    }
}
