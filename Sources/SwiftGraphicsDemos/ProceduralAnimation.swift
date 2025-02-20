import Algorithms
import CoreGraphicsSupport
import CoreGraphicsUnsafeConformances
import SwiftUI

// https://www.youtube.com/watch?v=qlfh_rv6khY

struct ProceduralAnimationDemoView: DemoView {
    @State
    var size: CGSize = .zero

    @State
    var creatures: [Creature] = [Creature(position: [200, 200], color: .orange), Creature(position: [500, 700], color: .purple)]

    init() {
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, _ in
                for creature in creatures {
                    context.draw(creature: creature)
                }
            }
            .onChange(of: timeline.date) {
                for (index, creature) in creatures.enumerated() {
                    var creature = creature
                    creature.move(node: 0, to: creature.nodes[0].position + creature.velocity)

                    let position = creature.nodes[0].position
                    if position.x <= 0 {
                        creature.velocity *= [-1, 1]
                        creature.nodes[0].position.x = 0
                    }
                    else if position.x >= size.width {
                        creature.velocity *= [-1, 1]
                        creature.nodes[0].position.x = size.width - 1
                    }
                    if position.y <= 0 {
                        creature.velocity *= [1, -1]
                        creature.nodes[0].position.y = 0
                    }
                    else if position.y >= size.height {
                        creature.velocity *= [1, -1]
                        creature.nodes[0].position.y = size.height - 1
                    }
                    creatures[index] = creature
                }
            }
        }
        .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
        .gesture {
            DragGesture()
                .onChanged { value in
                    creatures[0].move(node: 0, to: value.location)
                }
        }
    }
}

protocol ConstraintProtocol: Equatable, Hashable {
    var subject: Int { get }
    var target: Int { get }

    func constrain(subject: inout Creature.Node, target: Creature.Node)
}

struct DistanceConstraint: ConstraintProtocol {
    var subject: Int
    var target: Int
    var distance: Double

    func constrain(subject: inout Creature.Node, target: Creature.Node) {
        let distance = subject.position.distance(to: target.position)
        if distance > self.distance {
            let direction = (target.position - subject.position).normalized
            let newPosition = target.position - direction * self.distance
            subject.direction = direction
            subject.position = newPosition
        }
    }
}

struct AngleConstraint: ConstraintProtocol {
    var subject: Int
    var target: Int
    var relativeAngleRange: ClosedRange<Angle>

    func constrain(subject: inout Creature.Node, target: Creature.Node) {
        let distance = subject.position.distance(to: target.position)
        let targetAngle = Angle(from: subject.position, to: target.position)
        let relativeAngle = subject.direction.angle - targetAngle
        guard !relativeAngleRange.contains(relativeAngle) else {
            return
        }
        let clampedRelativeAngle = relativeAngle.clamped(to: relativeAngleRange)
        let newAngle = targetAngle + clampedRelativeAngle
        subject.direction = CGPoint(length: 1, angle: targetAngle)
        subject.position = target.position + CGPoint(length: -distance, angle: newAngle)
    }
}

struct Creature {
    struct Node: Equatable {
        var direction: CGPoint = [1, 0]
        var position: CGPoint
        var radius: Double
    }

    var color: Color
    var velocity: CGPoint = [5, 2]
    var nodes: [Node] = []
    var constraints: [any ConstraintProtocol] = []

    init(position: CGPoint, color: Color) {
        nodes = (0..<10).map { n in
            .init(position: [Double(n) * -30 + position.x, position.y], radius: 30 - Double(n))
        }
        self.color = color
        let constraints: [any ConstraintProtocol] = nodes.indices.windows(ofCount: 2).flatMap { nodes -> [any ConstraintProtocol] in
            [
                DistanceConstraint(subject: nodes.last!, target: nodes.first!, distance: 20),
                AngleConstraint(subject: nodes.last!, target: nodes.first!, relativeAngleRange: .degrees(-30) ... .degrees(30)),
            ]
        }
        self.constraints = constraints
    }

    mutating func move(node: Int, to position: CGPoint) {
        nodes[0].direction = (position - nodes[0].direction).normalized
        nodes[0].position = position
        update(fixed: 0)
    }

    mutating func update(fixed index: Int) {
        _ = update(fixed: index, constaints: constraints)
        nodes[0].direction = nodes[1].direction
    }

    mutating func update(fixed index: Int, constaints: [any ConstraintProtocol]) -> [any ConstraintProtocol] {
        let currentConstraints = constaints.filter { $0.target == index }
        var constraints = constaints.filter { $0.target != index }
        for constraint in currentConstraints {
            var subject = nodes[constraint.subject]
            let target = nodes[constraint.target]
            constraint.constrain(subject: &subject, target: target)
            nodes[constraint.subject] = subject
        }
        for constraint in currentConstraints {
            constraints = update(fixed: constraint.subject, constaints: constraints)
        }
        return constaints
    }
}

extension Angle {
    static let semicircle: Angle = .degrees(180)
    static let quartercircle: Angle = .degrees(90)
}

public extension Angle {
    func clamped(to range: ClosedRange<Angle>) -> Angle {
        .radians(radians.clamped(to: range.lowerBound.radians ... range.upperBound.radians))
    }
}

extension GraphicsContext {
    func draw(creature: Creature) {
        guard let first = creature.nodes.first, let last = creature.nodes.last else {
            return
        }
        let path = Path { path in
            path.move(to: first.position + -first.direction.perpendicular * first.radius)
            path.addRelativeArc(center: first.position, radius: first.radius, startAngle: first.direction.perpendicular.angle - .semicircle, delta: .degrees(180))

            for node in creature.nodes {
                path.addLine(to: node.position + node.direction.perpendicular * node.radius)
            }
            path.addRelativeArc(center: last.position, radius: last.radius, startAngle: last.direction.perpendicular.angle, delta: .degrees(180))
            for node in creature.nodes.reversed() {
                path.addLine(to: node.position - node.direction.perpendicular * node.radius)
            }
        }
        fill(path, with: .color(creature.color))

        fill(Path.dot(first.position + -first.direction.perpendicular * first.radius, radius: 10), with: .color(.black))
        fill(Path.dot(first.position + first.direction.perpendicular * first.radius, radius: 10), with: .color(.black))

        //            for node in creature.nodes {
        //                let path = Path.circle(center: node.position, radius: node.radius)
        //                stroke(path, with: .color(.black.opacity(0.2)))
        //                stroke(Path.line(from: node.position, to: node.position + node.direction * node.radius), with: .color(.black))
        //                draw(Text(node.direction.angle, format: .angle), at: node.position)
        //            }

    }
}
