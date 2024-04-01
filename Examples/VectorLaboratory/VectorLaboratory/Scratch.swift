import CoreGraphics
import CoreGraphicsSupport
import Everything
import Geometry
import SwiftUI
import VectorSupport
import Everything

extension CGPoint {
    func flipVertically(within rect: CGRect) -> CGPoint {
        CGPoint(x: x, y: rect.height - y)
    }
}

#if os(macOS)
    struct LastRightMouseDownLocationModifier: ViewModifier {
        @Binding
        var location: CGPoint?

        init(_ location: Binding<CGPoint?>) {
            _location = location
        }

        func body(content: Content) -> some View {
            content.onAppear(perform: {
                NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) {
                    if let frame = $0.window?.frame {
                        location = $0.locationInWindow.flipVertically(within: frame)
                    }
                    return $0
                }
            })
        }
    }

    extension View {
        func lastRightMouseDownLocation(_ location: Binding<CGPoint?>) -> some View {
            modifier(LastRightMouseDownLocationModifier(location))
        }
    }
#endif

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

public struct EmptyShape: Shape {
    public init() {
    }

    public func path(in rect: CGRect) -> Path {
        Path()
    }
}

public struct Identified<ID, Content>: Identifiable where ID: Hashable {
    public let id: ID
    public let content: Content
}

extension Identified: Equatable where Content: Equatable {
}

extension Identified: Comparable where Content: Comparable {
    public static func < (lhs: Identified<ID, Content>, rhs: Identified<ID, Content>) -> Bool {
        lhs.content < rhs.content
    }
}

public extension Array {
    func identifiedByIndex() -> [Identified<Int, Element>] {
        enumerated().map {
            Identified(id: $0.offset, content: $0.element)
        }
    }
}

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

public struct RelativeTimelineView<Schedule, Content>: View where Schedule: TimelineSchedule, Content: View {
    let schedule: Schedule
    let content: (TimelineViewDefaultContext, TimeInterval) -> Content

    @State
    var start: Date = .init()

    public init(schedule: Schedule, content: @escaping (TimelineViewDefaultContext, TimeInterval) -> Content, start: Date = Date()) {
        self.schedule = schedule
        self.content = content
        self.start = start
    }

    public var body: some View {
        TimelineView(schedule) { context in content(context, Date().timeIntervalSince(start)) }
    }
}

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

extension Angle: CustomStringConvertible {
    public var description: String {
        "\(degrees.formatted())°"
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
                            let path = Path(lineSegment: segment)
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
            return stride(from: includeZero ? 0 : width, through: d, by: width).map { Guide.line(Line.vertical(x: $0)) }
        }
    }
}
