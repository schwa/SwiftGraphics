import SwiftUI

protocol TurtleProtocol {
    mutating func set(position: CGPoint)
    mutating func set(angle: Angle)
    mutating func save()
    mutating func restore()
    mutating func turn(angle: Angle)
    mutating func forwards(distance: Double)
}

extension TurtleProtocol {
    mutating func turnLeft(angle: Angle) {
        self.turn(angle: -angle)
    }

    mutating func turnRight(angle: Angle) {
        self.turn(angle: angle)
    }
}

enum TurtleCommand {
    case setPosition(CGPoint)
    case setAngle(Angle)
    case save
    case restore
    case turn(angle: Angle)
    case forwards(distance: Double)
}

extension TurtleProtocol {
    mutating func replay(commands: [TurtleCommand]) {
        for command in commands {
            switch command {
            case .setPosition(let position):
                set(position: position)
            case .setAngle(let angle):
                set(angle: angle)
            case .save:
                save()
            case .restore:
                restore()
            case .turn(let angle):
                turn(angle: angle)
            case .forwards(let distance):
                forwards(distance: distance)
            }
        }
    }
}
