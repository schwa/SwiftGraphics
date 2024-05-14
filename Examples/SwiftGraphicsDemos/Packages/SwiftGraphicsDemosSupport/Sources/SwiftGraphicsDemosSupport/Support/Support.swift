import CoreGraphics
import CoreGraphicsSupport
import Everything
import Foundation
import MetalKit
import MetalSupport
import RenderKit
import RenderKitShaders
import Shapes2D
import simd
import SwiftUI

// swiftlint:disable identifier_name

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
        let diameter = sqrt(rect.width ** 2 + rect.height ** 3)
        self = .init(center: center, diameter: diameter)
    }
}

extension Triangle {
    init(containing circle: Shapes2D.Circle) {
        let a = circle.center + CGPoint(distance: circle.radius * 2, angle: Angle.degrees(0))
        let b = circle.center + CGPoint(distance: circle.radius * 2, angle: Angle.degrees(120))
        let c = circle.center + CGPoint(distance: circle.radius * 2, angle: Angle.degrees(240))
        self = .init(a, b, c)
    }
}

class Once {
    // TODO: The thread safety, it's missing!!!!
    var tokens: Set<AnyHashable> = []
    static let shared = Once()
}

func once(_ token: AnyHashable, block: () throws -> Void) rethrows {
    guard Once.shared.tokens.insert(token).inserted else {
        return
    }
    try block()
}

extension MTLOrigin: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Int...) {
        self = .init(x: elements[0], y: elements[1], z: elements[2])
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

extension MTLBuffer {
    func contentsBuffer() -> UnsafeMutableRawBufferPointer {
        UnsafeMutableRawBufferPointer(start: contents(), count: length)
    }

    func contentsBuffer<T>(of type: T.Type) -> UnsafeMutableBufferPointer<T> {
        contentsBuffer().bindMemory(to: type)
    }
}

extension MTLBuffer {
    func labelled(_ label: String) -> MTLBuffer {
        self.label = label
        return self
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

private class PrintOnceManager {
    static let instance = PrintOnceManager()

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

struct Pair<LHS, RHS> {
    var lhs: LHS
    var rhs: RHS

    init(_ lhs: LHS, _ rhs: RHS) {
        self.lhs = lhs
        self.rhs = rhs
    }

    init(_ value: (LHS, RHS)) {
        lhs = value.0
        rhs = value.1
    }
}

extension Pair: Equatable where LHS: Equatable, RHS: Equatable {
}

extension Pair: Hashable where LHS: Hashable, RHS: Hashable {
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
                content.onAppear(perform: {
                    NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) {
                        if let frame = $0.window?.frame {
                            let windowLocation = $0.locationInWindow.flipVertically(within: frame)
                            let localWindowFrame = geometry.frame(in: coordinateSpace)
                            location = windowLocation - localWindowFrame.origin
                        }
                        return $0
                    }
                })
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
    init() {
    }

    func path(in rect: CGRect) -> Path {
        Path()
    }
}

// MARK: -

struct Identified<ID, Content>: Identifiable where ID: Hashable {
    var id: ID
    var content: Content
}

extension Identified where ID == UUID {
    init(_ content: Content) {
        id = .init()
        self.content = content
    }
}

extension Identified: Equatable where Content: Equatable {
}

extension Identified: Comparable where Content: Comparable {
    static func < (lhs: Identified<ID, Content>, rhs: Identified<ID, Content>) -> Bool {
        lhs.content < rhs.content
    }
}

extension Identified: Encodable where ID: Encodable, Content: Encodable {
}

extension Identified: Decodable where ID: Decodable, Content: Decodable {
}

extension Array {
    func identifiedByIndex() -> [Identified<Int, Element>] {
        enumerated().map {
            Identified(id: $0.offset, content: $0.element)
        }
    }
}

// MARK: -

struct JSONCodingTransferable<Element>: Transferable where Element: Codable {
    let element: Element

    init(element: Element) {
        self.element = element
    }

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

struct RelativeTimelineView<Schedule, Content>: View where Schedule: TimelineSchedule, Content: View {
    let schedule: Schedule
    let content: (TimelineViewDefaultContext, TimeInterval) -> Content

    @State
    var start: Date = .init()

    init(schedule: Schedule, @ViewBuilder content: @escaping (TimelineViewDefaultContext, TimeInterval) -> Content, start: Date = Date()) {
        self.schedule = schedule
        self.content = content
        self.start = start
    }

    var body: some View {
        TimelineView(schedule) { context in content(context, Date().timeIntervalSince(start)) }
    }
}

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
        }
        else {
            nil
        }
    }
}

extension Sequence {
    // TODO: Deprecate do not use in production.
    var tuple: (Element, Element) {
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
        }
        else {
            guard let previous = element else {
                fatalError()
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
        }
        else {
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
        Self.rulerGuides(width: 20, angle: .zero),
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
                        fatalError()
                    }
                }
            }
        }
    }

    static func rulerGuides(width: Double, angle: Angle, includeZero: Bool = true) -> (_ origin: CGPoint, _ bounds: CGRect) -> [Guide] {
        { _, bounds in
            let d = CGPoint(bounds.size).distance
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

    func transformed(_ modify: @escaping (CGFloat) -> CGFloat) -> Binding {
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
            fatalError()
        }
        try container.encode(components)
    }
}

@propertyWrapper
struct CodableAppStorage<Value: Codable>: DynamicProperty {
    var key: String

    @State
    var storage: Value

    var wrappedValue: Value {
        get {
            storage
        }
        nonmutating set {
            storage = newValue
            let data = try! JSONEncoder().encode(newValue)
            let string = String(data: data, encoding: .utf8)!
            UserDefaults.standard.setValue(string, forKey: key)
        }
    }

    init(wrappedValue: Value, _ key: String) {
        self.key = key
        if let string = UserDefaults.standard.string(forKey: key) {
            let data = string.data(using: .utf8)!
            let value = try! JSONDecoder().decode(Value.self, from: data)
            _storage = .init(initialValue: value)
        }
        else {
            _storage = .init(initialValue: wrappedValue)
        }
    }
}

extension CodableAppStorage where Value: ExpressibleByNilLiteral {
    init(_ key: String) {
        self.key = key
        if let string = UserDefaults.standard.string(forKey: key) {
            let data = string.data(using: .utf8)!
            let value = try! JSONDecoder().decode(Value.self, from: data)
            _storage = .init(initialValue: value)
        }
        else {
            _storage = .init(initialValue: nil)
        }
    }
}

@resultBuilder
enum ViewModifierBuilder {
    static func buildExpression<Content>(_ content: Content) -> Content where Content: ViewModifier {
        content
    }

    static func buildBlock() -> EmptyViewModifier {
        EmptyViewModifier()
    }

    static func buildBlock<Content>(_ content: Content) -> Content where Content: ViewModifier {
        content
    }

    static func buildEither<TrueContent, FalseContent>(first: TrueContent) -> ConditionalViewModifier<TrueContent, FalseContent> where TrueContent: ViewModifier, FalseContent: ViewModifier {
        .init(trueModifier: first)
    }

    static func buildEither<TrueContent, FalseContent>(second: FalseContent) -> ConditionalViewModifier<TrueContent, FalseContent> where TrueContent: ViewModifier, FalseContent: ViewModifier {
        .init(falseModifier: second)
    }
}

struct ConditionalViewModifier<TrueModifier, FalseModifier>: ViewModifier where TrueModifier: ViewModifier, FalseModifier: ViewModifier {
    var trueModifier: TrueModifier?
    var falseModifier: FalseModifier?

    init(trueModifier: TrueModifier) {
        self.trueModifier = trueModifier
    }

    init(falseModifier: FalseModifier) {
        self.falseModifier = falseModifier
    }

    func body(content: Content) -> some View {
        if let trueModifier {
            content.modifier(trueModifier)
        }
        else if let falseModifier {
            content.modifier(falseModifier)
        }
        else {
            fatalError()
        }
    }
}

/// A view modifier that does nothing.
struct EmptyViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension Array where Element: Identifiable {
    @discardableResult
    mutating func remove(identifiedBy id: Element.ID) -> Element {
        if let index = firstIndex(identifiedBy: id) {
            remove(at: index)
        }
        else {
            fatalError()
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
        self % 2 == 0
    }
}

extension View {
    func onDragGesture(onChanged: @escaping (DragGesture.Value) -> Void, onEnded: @escaping (DragGesture.Value) -> Void) -> some View {
        gesture(DragGesture().onChanged(onChanged).onEnded(onEnded))
    }
}

extension View {
    func onSpatialTapGesture(count: Int = 1, coordinateSpace: CoordinateSpace = .local, _ ended: @escaping (SpatialTapGesture.Value) -> Void) -> some View {
        gesture(SpatialTapGesture(count: count, coordinateSpace: coordinateSpace).onEnded(ended))
    }
}

extension Array {
    subscript(relative index: Int) -> Element {
        get {
            if index >= 0 {
                self[index]
            }
            else {
                self[count + index]
            }
        }
        set {
            if index >= 0 {
                self[index] = newValue
            }
            else {
                self[count + index] = newValue
            }
        }
    }
}
