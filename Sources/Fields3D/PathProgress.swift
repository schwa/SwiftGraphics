//
//  Untitled.swift
//
//
//  Created by Jonathan Wight on 6/27/24.
//


import SwiftUI
import CoreGraphicsSupport

struct PathProgress: View {


    var body: some View {
        let path = Path.curvedLine(length: 100, curl: 0.5).applying(.translation(x: 50, y: 50))
        let lineWidth = 4.0
        TimelineView(.animation) { timeline in
            let delta = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in

                let parameters: [(offset: Double, width: Double, speed: Double, color: Color)] = [
                    (0, 0.1, 1.0, .green),
                    (0.5, 0.1, 1.0, .red),
                    (0.75, 0.1, -1.0, .green),
                ]

                for (offset, width, speed, color) in parameters {
                    let delta = delta * speed
                    context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: lineWidth)
                    let trimmed = path.betterTrimedPath(from: delta + offset, to: delta + offset + width)
                    context.stroke(trimmed, with: .color(color), lineWidth: lineWidth)
                }
            }
        }
        .border(Color.blue)
    }
}

public extension Path {
    func betterTrimedPath(from: Double, to: Double) -> Path {
        let from = from.wrapped(to: 0...1)
        let to = to.wrapped(to: 0...1)
        if from < to {
            return trimmedPath(from: from, to: to)
        }
        else {
            let a = trimmedPath(from: from, to: 1.0)
            let b = trimmedPath(from: 0, to: to)
            return a + b
        }
    }
}

#Preview {
    PathProgress()
}

extension Path {
    static func curvedLine(length: Double, curl: Double) -> Path {
        var path = Path()

        // Starting point
        let startPoint = CGPoint(x: 0, y: 0)
        path.move(to: startPoint)

        if curl == 0 {
            // Straight line case
            path.addLine(to: CGPoint(x: length, y: 0))
        } else {
            // Arc case
            let radius = length / (2 * .pi) / curl
            let angle = length / radius

            path.addArc(
                center: CGPoint(x: radius, y: 0),
                radius: radius,
                startAngle: .radians(0),
                endAngle: .radians(angle),
                clockwise: false
            )
        }

        return path
    }
}
