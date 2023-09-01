// swiftlint:disable indentation_width

#if os(macOS)
    import AppKit
    import CoreGraphics
    import Foundation

    // swiftlint:disable identifier_name

    class OmniGraffleDocumentModel {
        let path: String
        var frame: CGRect!
        var rootNode: OmniGraffleGroup!
        var nodesByID: [Int: OmniGraffleNode] = [:]

        init(path: String) throws {
            self.path = path
            // TODO:
            unimplemented()
            // try load()
        }
    }

    class OmniGraffleNode {
        weak var parent: OmniGraffleNode?
        var dictionary: NSDictionary!
        var ID: Int { dictionary["ID"] as! Int }

        init() {
        }
    }

    class OmniGraffleGroup: OmniGraffleNode {
        var children: [OmniGraffleNode] = []

        init(children: [OmniGraffleNode]) {
            self.children = children
        }
    }

    class OmniGraffleShape: OmniGraffleNode {
        var shape: String? { dictionary["Shape"] as? String }
        var bounds: CGRect { NSRectFromString(dictionary["Bounds"] as! String) }
        lazy var lines: [OmniGraffleLine] = []
    }

    class OmniGraffleLine: OmniGraffleNode {
        var start: CGPoint {
            let strings = dictionary["Points"] as! [String]
            return NSPointFromString(strings[0])
        }

        var end: CGPoint {
            let strings = dictionary["Points"] as! [String]
            return NSPointFromString(strings[1])
        }

        var head: OmniGraffleNode?
        var tail: OmniGraffleNode?
    }

    // TODO:
    extension OmniGraffleDocumentModel {
//    func load() throws {
//        let data = try Data(contentsOfCompressedFile: path)
//        // TODO: Swift 2
//        if let d = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? NSDictionary {
//            _processRoot(d)
//            let origin = NSPointFromString(d["CanvasOrigin"] as! String)
//            let size = NSSizeFromString(d["CanvasSize"] as! String)
//            frame = CGRect(origin: origin, size: size)
//            print(nodesByID)
//
//            let nodes = nodesByID.values.filter {
//                (node: Node) -> Bool in
//                node is OmniGraffleLine
//            }
//            for node in nodes {
//                let line = node as! OmniGraffleLine
//                var headID: Int?
//                var tailID: Int?
//                if let headDictionary = line.dictionary["Head"] as? NSDictionary {
//                    headID = headDictionary["ID"] as? Int
//                }
//                if let tailDictionary = line.dictionary["Tail"] as? NSDictionary {
//                    tailID = tailDictionary["ID"] as? Int
//                }
//                if headID != nil && tailID != nil {
//                    let head = nodesByID[headID!] as! OmniGraffleShape
//                    line.head = head
//                    head.lines.append(line)
//
//                    let tail = nodesByID[headID!] as! OmniGraffleShape
//                    line.tail = tail
//                    tail.lines.append(line)
//                }
//            }
//        }
//    }

        func _processRoot(_ d: NSDictionary) {
            let graphicslist = d["GraphicsList"] as! [NSDictionary]
            var children: [OmniGraffleNode] = []
            for graphic in graphicslist {
                if let node = _processDictionary(graphic) {
                    children.append(node)
                }
            }
            let group = OmniGraffleGroup(children: children)
            rootNode = group
        }

        func _processDictionary(_ d: NSDictionary) -> OmniGraffleNode! {
            if let className = d["Class"] as? String {
                switch className {
                case "Group":
                    var children: [OmniGraffleNode] = []
                    if let graphics = d["Graphics"] as? [NSDictionary] {
                        children = graphics.map { (d: NSDictionary) -> OmniGraffleNode in
                            self._processDictionary(d)
                        }
                    }
                    let group = OmniGraffleGroup(children: children)
                    group.dictionary = d
                    nodesByID[group.ID] = group
                    return group
                case "ShapedGraphic":
                    let shape = OmniGraffleShape()
                    shape.dictionary = d
                    nodesByID[shape.ID] = shape
                    return shape
                case "LineGraphic":
                    let line = OmniGraffleLine()
                    line.dictionary = d
                    nodesByID[line.ID] = line
                    return line
                default:
                    warning("Unknown: \(className)")
                }
            }
            return nil
        }
    }
#endif
