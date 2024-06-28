import SwiftUI
import CoreGraphicsSupport

struct PathTurtle: TurtleProtocol {
    var path: Path = .init()
    var stack: [(CGPoint, Angle)] = []
    var position = CGPoint.zero
    var angle = Angle(degrees: 0)

    mutating func set(position: CGPoint) {
        self.position = position
    }

    mutating func set(angle: Angle) {
        self.angle = angle
    }

    mutating func save() {
        stack.append((position, angle))
    }

    mutating func restore() {
        (position, angle) = stack.popLast()!
    }

    mutating func turn(angle: Angle) {
        self.angle += angle
    }

    mutating func forwards(distance: Double) {
        let nextPosition = CGPoint(x: position.x + CoreGraphics.cos(angle.radians) * distance, y: position.y + CoreGraphics.sin(angle.radians) * distance)
        path = path + Path { path in path.addLines([position, nextPosition]) }
        position = nextPosition
    }
}
