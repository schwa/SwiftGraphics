public struct TreeIterator <Element>: IteratorProtocol {
    public enum Mode {
        case depthFirst
        case breadthFirst
    }
    private let mode: Mode
    private var nodes: [Element]
    private let children: (Element) -> [Element]?

    private init(mode: Mode, nodes: [Element], children: @escaping (Element) -> [Element]?) {
        self.mode = mode
        self.nodes = nodes
        self.children = children
    }

    public mutating func next() -> Element? {
        guard !nodes.isEmpty else {
            return nil
        }
        switch mode {
        case .depthFirst:
            let current = nodes.removeLast()
            if let children = children(current) {
                nodes.append(contentsOf: children.reversed())
            }
            return current

        case .breadthFirst:
            let current = nodes.removeFirst()
            if let children = children(current) {
                nodes.append(contentsOf: children)
            }
            return current
        }
    }
}

public extension TreeIterator {
    init(mode: Mode, root: Element, children: @escaping (Element) -> [Element]?) {
        self.init(mode: mode, nodes: [root], children: children)
    }

    init(mode: Mode, root: Element, children keyPath: KeyPath<Element, [Element]?>) {
        self.init(mode: mode, nodes: [root]) { node -> [Element]? in
            node[keyPath: keyPath]
        }
    }

    init(mode: Mode, root: Element, children keyPath: KeyPath<Element, [Element]>) {
        self.init(mode: mode, nodes: [root]) { node -> [Element]? in
            node[keyPath: keyPath]
        }
    }
}
