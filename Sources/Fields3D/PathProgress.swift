//
//  Untitled.swift
//
//
//  Created by Jonathan Wight on 6/27/24.
//

import CoreGraphicsSupport
import SwiftUI

struct PathProgress: View {
    @ViewBuilder
    var example1: some View {
        // let path = Path.curvedLine(length: 100, curl: 0.5).applying(.translation(x: 50, y: 50))
        let path = Path.xyzzy(bounds: CGRect(x: 0, y: 0, width: 200, height: 200)).applying(.translation(x: 100, y: 150))
        let lineWidth = 2.0
        TimelineView(.animation) { timeline in
            let delta = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                let parameters: [(offset: Double, width: Double, speed: Double, color: Color)] = [
                    (0, 0.05, 1.0, .green.opacity(0.25)),
                    (0.5, 0.05, 1.0, .green.opacity(0.5)),
                    (0.75, 0.05, 1.0, .green),
                ]

                for (offset, width, speed, color) in parameters {
                    let delta = delta * speed
                    context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: lineWidth)
                    let trimmed = path.betterTrimedPath(from: delta + offset, to: delta + offset + width)
                    context.stroke(trimmed, with: .color(color), lineWidth: lineWidth)
                }
            }
        }
        .border(Color.red)
    }

    @ViewBuilder
    var example2: some View {
        let lineWidth = 2.0

//        let path = Path(ellipseIn: CGRect(center: CGPoint(100, 100), radius: 50))
//        + Path(ellipseIn: CGRect(center: CGPoint(100, 100), radius: 40))
//        + Path(ellipseIn: CGRect(center: CGPoint(100, 100), radius: 30))
//        + Path(ellipseIn: CGRect(center: CGPoint(100, 100), radius: 20))
        TimelineView(.animation) { timeline in
            let delta = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let bounds = CGRect(size: size).insetBy(dx: 10, dy: 4)
                let path = Path.hilbertCurve(in: bounds, order: 6)
                let parameters: [(offset: Double, width: Double, speed: Double, color: Color)] = [
                    (0, 0.20, -0.5, .green.opacity(0.5)),
                    (0.25, 0.15, 0.4, .yellow.opacity(0.5)),
                    (0.50, 0.10, -0.3, .red.opacity(0.5)),
                    (0.75, 0.05, 0.2, .blue),
                ]
                context.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: lineWidth)

                for (offset, width, speed, color) in parameters {
                    let delta = delta * speed
                    let trimmed = path.betterTrimedPath(from: delta + offset, to: delta + offset + width)
                    context.stroke(trimmed, with: .color(color), lineWidth: lineWidth)
                }
            }
        }
    }

    var body: some View {
        example2
    }
}

#Preview {
    PathProgress()
}

public extension Path {
    static func xyzzy(bounds: CGRect) -> Path {
        let distance = 2.0
        let symbols = LSystem.fractalBinaryTree.apply(iterations: 7)
        var turtle = PathTurtle()
        turtle.position = bounds.midXMidY
        turtle.angle = .degrees(270)
        for symbol in symbols {
            switch symbol {
            case "0", "1":
                turtle.forwards(distance: distance)
            case "[":
                turtle.save()
                turtle.turnLeft(angle: .degrees(45))
            case "]":
                turtle.restore()
                turtle.turnRight(angle: .degrees(45))
            default:
                fatalError("Unrecognised symbol \(symbol)")
            }
        }
        return turtle.path
    }
}
