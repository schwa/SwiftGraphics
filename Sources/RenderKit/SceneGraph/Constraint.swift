import SIMDSupport

protocol Constraint {
}

extension SceneGraph {
    mutating func update(with: [any Constraint]) {
    }
}

struct BallConstraint2: Constraint {
    var source: Node.ID
    var target: Node.ID
    var distance: Float
    var rotation: Rotation
}
