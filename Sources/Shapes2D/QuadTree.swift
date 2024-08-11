import CoreGraphics

// swiftlint:disable force_unwrapping

// This is a "CGPoint" quadtree - see http://www.codeproject.com/Articles/30535/A-Simple-QuadTree-Implementation-in-C for a discussion of point vs "region' quad tree

struct QuadTreeConfig {
    let minimumNodeSize: CGSize
    let maximumObjectsPerNode: Int
}

public class QuadTree<T> {
    public var frame: CGRect { rootNode!.frame }
    public var rootNode: QuadTreeNode<T>?
    private let config: QuadTreeConfig

    public required init(frame: CGRect, minimumNodeSize: CGSize = CGSize(width: 1, height: 1), maximumObjectsPerNode: Int = 8) {
        config = QuadTreeConfig(minimumNodeSize: minimumNodeSize, maximumObjectsPerNode: maximumObjectsPerNode)
        rootNode = QuadTreeNode(config: config, frame: frame)
    }

    public func addObject(object: T, point: CGPoint) {
        assert(frame.contains(point))
        rootNode!.addObject(object, point: point)
    }

    public func objectsInRect(rect: CGRect) -> [T] {
        assert(frame.intersects(rect))
        return rootNode!.objectsInRect(rect)
    }
}

public class QuadTreeNode<T> {
    public typealias Item = (point: CGPoint, object: T)

    //    var topLeft: QuadTreeNode?
    //    var topRight: QuadTreeNode?
    //    var bottomLeft: QuadTreeNode?
    //    var bottomRight: QuadTreeNode?

    public let frame: CGRect
    let config: QuadTreeConfig

    public var subnodes: [QuadTreeNode] = []
    public lazy var items: [Item] = []

    var isLeaf: Bool { subnodes.isEmpty }
    var canExpand: Bool { frame.size.width >= config.minimumNodeSize.width * 2.0 && frame.size.height >= config.minimumNodeSize.height * 2.0 }

    init(config: QuadTreeConfig, frame: CGRect) {
        self.config = config
        self.frame = frame
    }

    func addItem(_ item: Item) {
        if isLeaf {
            items.append(item)
            if items.count >= config.maximumObjectsPerNode && canExpand {
                expand()
            }
        } else {
            let subnode = subnodeForPoint(item.point)!
            subnode.addItem(item)
        }
    }

    func addObject(_ object: T, point: CGPoint) {
        let item = Item(point: point, object: object)
        addItem(item)
    }

    func itemsInRect(_ rect: CGRect) -> [Item] {
        var foundItems: [Item] = []
        for item in items where rect.contains(item.point) {
            foundItems.append(item)
        }
        for subnode in subnodes where subnode.frame.intersects(rect) {
            foundItems += subnode.itemsInRect(rect)
        }
        return foundItems
    }

    func objectsInRect(_ rect: CGRect) -> [T] {
        itemsInRect(rect).map(\.object)
    }

    func expand() {
        assert(canExpand)
        subnodes = [
            QuadTreeNode(config: config, frame: frame.quadrant(.minXMinY)),
            QuadTreeNode(config: config, frame: frame.quadrant(.maxXMinY)),
            QuadTreeNode(config: config, frame: frame.quadrant(.minXMaxY)),
            QuadTreeNode(config: config, frame: frame.quadrant(.maxXMaxY))
        ]
        for item in items {
            let node = subnodeForPoint(item.point)!
            node.addItem(item)
        }

        items = []
    }

    func subnodeForPoint(_ point: CGPoint) -> QuadTreeNode? {
        assert(frame.contains(point))
        let quadrant = Quadrant.from(point: point, rect: frame)
        return subnodeForQuadrant(quadrant!)
    }

    func subnodeForQuadrant(_ quadrant: Quadrant) -> QuadTreeNode? {
        if !subnodes.isEmpty {
            switch quadrant {
            case .minXMinY:
                subnodes[0]
            case .maxXMinY:
                subnodes[1]
            case .minXMaxY:
                subnodes[2]
            case .maxXMaxY:
                subnodes[3]
            }
        } else {
            nil
        }
    }
}
