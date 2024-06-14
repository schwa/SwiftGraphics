//
//  BouncingBallsSimulation.swift
//  Random
//
//  Created by Jonathan Wight on 6/9/24.
//

import Foundation

struct Ball {
    var position: CGPoint
    var velocity: CGVector
}

struct BouncingBallsSimulation {
    var balls: [Ball]
    var size: CGSize
    private var lastUpdateTime: Date?

    init(size: CGSize, numberOfBalls: Int, speed: Double = 200) {
        let size = CGSize(max(1, size.width), max(1, size.height))
        self.size = size
        self.balls = (0..<numberOfBalls).map { _ in
            let position = CGPoint(x: CGFloat.random(in: 0..<size.width), y: CGFloat.random(in: 0..<size.height))
            let velocity = CGVector(dx: CGFloat.random(in: -speed..<speed), dy: CGFloat.random(in: -speed..<speed))
            return Ball(position: position, velocity: velocity)
        }
        self.lastUpdateTime = nil
    }

    mutating func simulate(currentTime: Date) {
        guard let lastTime = lastUpdateTime else {
            lastUpdateTime = currentTime
            return
        }

        let timeInterval = currentTime.timeIntervalSince(lastTime)
        lastUpdateTime = currentTime

        for i in 0..<balls.count {
            var ball = balls[i]
            ball.position.x += ball.velocity.dx * CGFloat(timeInterval)
            ball.position.y += ball.velocity.dy * CGFloat(timeInterval)

            // Check for collision with walls and reflect
            if ball.position.x <= 0 || ball.position.x >= size.width {
                ball.velocity.dx *= -1
                ball.position.x = max(0, min(ball.position.x, size.width))
            }
            if ball.position.y <= 0 || ball.position.y >= size.height {
                ball.velocity.dy *= -1
                ball.position.y = max(0, min(ball.position.y, size.height))
            }

            balls[i] = ball
        }
    }
}
