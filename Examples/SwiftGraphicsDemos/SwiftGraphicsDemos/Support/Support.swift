import CoreGraphics
import CoreGraphicsSupport
import Everything
import SwiftUI
import Shapes2D
import Everything

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

public struct EmptyShape: Shape {
    public init() {
    }

    public func path(in rect: CGRect) -> Path {
        Path()
    }
}

// MARK: -

public struct Identified<ID, Content>: Identifiable where ID: Hashable {
    public var id: ID
    public var content: Content

    init(id: ID, content: Content) {
        self.id = id
        self.content = content
    }
}

public extension Identified where ID == UUID {
    init(_ content: Content) {
        self.id = .init()
        self.content = content
    }
}

extension Identified: Equatable where Content: Equatable {
}

extension Identified: Comparable where Content: Comparable {
    public static func < (lhs: Identified<ID, Content>, rhs: Identified<ID, Content>) -> Bool {
        lhs.content < rhs.content
    }
}

extension Identified: Encodable where ID: Encodable, Content: Encodable {
}

extension Identified: Decodable where ID: Decodable, Content: Decodable {
}


public extension Array {
    func identifiedByIndex() -> [Identified<Int, Element>] {
        enumerated().map {
            Identified(id: $0.offset, content: $0.element)
        }
    }
}

// MARK: -

public struct JSONCodingTransferable<Element>: Transferable where Element: Codable {
    let element: Element

    public init(element: Element) {
        self.element = element
    }

    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .json) { layer in
            try JSONEncoder().encode(layer.element)
        } importing: { data in
            let element = try JSONDecoder().decode(Element.self, from: data)
            return Self(element: element)
        }
    }
}

// MARK: -


public struct RelativeTimelineView<Schedule, Content>: View where Schedule: TimelineSchedule, Content: View {
    let schedule: Schedule
    let content: (TimelineViewDefaultContext, TimeInterval) -> Content

    @State
    var start: Date = .init()

    public init(schedule: Schedule, @ViewBuilder content: @escaping (TimelineViewDefaultContext, TimeInterval) -> Content, start: Date = Date()) {
        self.schedule = schedule
        self.content = content
        self.start = start
    }

    public var body: some View {
        TimelineView(schedule) { context in content(context, Date().timeIntervalSince(start)) }
    }
}

// MARK: -

public extension GraphicsContext {
    func drawDot(at position: CGPoint) {
        fill(Path.circle(center: position, radius: 2), with: .color(.black))
    }
}

public extension Array {
    func get(index: Index) -> Element? {
        if (startIndex ..< endIndex).contains(index) {
            self[index]
        }
        else {
            nil
        }
    }
}

public extension Sequence {
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

public struct PeekingWindowIterator<I>: IteratorProtocol where I: IteratorProtocol {
    public typealias Element = (previous: I.Element?, current: I.Element, next: I.Element?)

    var iterator: I
    var element: Element?

    public init(iterator: I) {
        self.iterator = iterator
    }

    public mutating func next() -> Element? {
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

public extension Sequence {
    func peekingWindow() -> PeekingWindowIterator<Iterator> {
        PeekingWindowIterator(iterator: makeIterator())
    }
}

public extension GraphicsContext {
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
        positions.forEach {
            let image = Image(systemName: "circle.fill")
            draw(image, in: CGRect(center: $0, size: size))
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
        return Binding {
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
        guard let components = self.resolve(in: .init()).cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?.components else {
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
            return storage
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
            self._storage = .init(initialValue: value)
        }
        else {
            self._storage = .init(initialValue: wrappedValue)
        }
    }
}

extension CodableAppStorage where Value : ExpressibleByNilLiteral {
    init(_ key: String) {
        self.key = key
        if let string = UserDefaults.standard.string(forKey: key) {
            let data = string.data(using: .utf8)!
            let value = try! JSONDecoder().decode(Value.self, from: data)
            self._storage = .init(initialValue: value)
        }
        else {
            self._storage = .init(initialValue: nil)
        }
    }


}


@resultBuilder
struct ViewModifierBuilder {
    static func buildExpression<Content>(_ content: Content) -> Content where Content: ViewModifier {
        content
    }
    static func buildBlock() -> EmptyViewModifier {
        return EmptyViewModifier()
    }

    static func buildBlock<Content>(_ content: Content) -> Content where Content: ViewModifier {
        content
    }

    static func buildEither<TrueContent, FalseContent>(first: TrueContent) -> ConditionalViewModifier<TrueContent, FalseContent> where TrueContent : ViewModifier, FalseContent : ViewModifier {
        .init(trueModifier: first)
    }

    static func buildEither<TrueContent, FalseContent>(second: FalseContent) -> ConditionalViewModifier<TrueContent, FalseContent> where TrueContent : ViewModifier, FalseContent : ViewModifier {
        .init(falseModifier: second)
    }
}

struct ConditionalViewModifier <TrueModifier, FalseModifier>: ViewModifier where TrueModifier: ViewModifier, FalseModifier: ViewModifier {

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

public extension Array where Element: Identifiable {
    @discardableResult
    mutating func remove(identifiedBy id: Element.ID) -> Element {
        if let index = firstIndex(identifiedBy: id) {
            return remove(at: index)
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
