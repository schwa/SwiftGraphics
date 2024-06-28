import Foundation
import CoreGraphics
import SwiftUI

struct GraphicsContextTurtle: TurtleProtocol {

    var context: any GraphicsContextProtocol
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
        context.stroke(Path { path in path.addLines([position, nextPosition]) }, with: .color(.black))
        position = nextPosition
    }
}
