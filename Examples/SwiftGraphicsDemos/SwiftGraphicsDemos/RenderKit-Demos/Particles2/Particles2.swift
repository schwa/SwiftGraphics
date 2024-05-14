import CoreGraphicsSupport
import DemosSupport
import simd
import SwiftUI

struct VerletObject {
    var id: Int
    var position_current: SIMD2<Float> {
        didSet {
            precondition(position_current.x.isNaN == false && position_current.y.isNaN == false)
        }
    }

    var position_old: SIMD2<Float>
    var acceleration: SIMD2<Float> {
        didSet {
            precondition(acceleration.x.isNaN == false && acceleration.y.isNaN == false)
        }
    }

    var color: SIMD3<Float>
    var radius: Float

    init(id: Int, position_current: SIMD2<Float>) {
        self.id = id
        self.position_current = position_current
        position_old = position_current
        acceleration = .zero
        color = [Float.random(in: 0 ... 1), Float.random(in: 0 ... 1), Float.random(in: 0 ... 1)]
        radius = Float.random(in: 3 ... 10)
    }

    mutating func updatePosition(_ dt: Float) {
        let velocity = position_current - position_old
        // Save current position
        position_old = position_current
        // Perform Verlet integration
        position_current = position_current + velocity + acceleration * dt * dt
        // Reset acceleration
        acceleration = .zero
    }

    mutating func accelerate(_ acc: SIMD2<Float>) {
        acceleration += acc
    }
}

extension VerletObject: CustomStringConvertible {
    var description: String {
        "\(position_current) \(acceleration)"
    }
}

struct Solver {
    var objects: [VerletObject] = []
    var gravity: SIMD2<Float> = [0.0, 1_000.0]

    var lookup: SpatialLookupTable<[SIMD2<Float>]> = .init(size: [1_000, 1_000])

    mutating func update(_ dt: Float) {
        let sub_steps = 8
        let sub_dt = dt / Float(sub_steps)
        for _ in 0 ..< sub_steps {
            applyGravity()
            applyConstraint()
            lookup.update(points: objects.map(\.position_current), radius: 5)
            solveCollisions()
            updatePositions(sub_dt)
        }
    }

    mutating func updatePositions(_ dt: Float) {
        objects.withEach { obj in
            obj.updatePosition(dt)
        }
    }

    mutating func applyGravity() {
        objects.withEach { obj in
            obj.accelerate(gravity)
        }
    }

    mutating func applyConstraint() {
        let position: SIMD2<Float> = [500, 500]
        let radius: Float = 250.0
        objects.withEach { obj in
            let to_obj = obj.position_current - position
            let dist = to_obj.length
            // 50 is the default radius
            if dist > radius - obj.radius {
                let n = to_obj / dist
                obj.position_current = position + n * (radius - obj.radius)
            }
        }
    }

    mutating func solveCollisions() {
//        var positions = objects.map(\.position_current)

        for i in objects.startIndex ..< objects.endIndex {
            var object_1 = objects[i]
//            for k in objects.startIndex ..< objects.endIndex where k != i{
            lookup.indicesNear(point: object_1.position_current) { k in
                if k == i {
                    return
                }
                var object_2 = objects[k]
                let collision_axis = object_1.position_current - object_2.position_current
                let dist = length(collision_axis)
                if dist < object_1.radius + object_2.radius {
                    assert(dist != 0)
                    let n = collision_axis / dist
                    let delta = object_1.radius + object_2.radius - dist
                    object_1.position_current += 0.5 * delta * n
                    object_2.position_current -= 0.5 * delta * n
                    objects[i] = object_1
                    objects[k] = object_2
                }
            }
        }
    }
}

extension MutableCollection where Self.Index: Strideable, Self.Index.Stride: SignedInteger {
    mutating func withEach(_ closure: (inout Element) throws -> Void) rethrows {
        for index in startIndex ..< endIndex {
            try closure(&self[index])
        }
    }
}

extension Solver {
    func draw(context: GraphicsContext) {
        for object in objects {
            let path = Path { path in
                path.addEllipse(in: CGRect(center: CGPoint(object.position_current), radius: Double(object.radius)))
            }
            context.fill(path, with: .color(Color(SIMD3<Double>(object.color))))
        }
        context.stroke(Path(ellipseIn: .init(center: [500, 500], radius: 250)), with: .color(.red))
    }
}

struct Particles2View: View, DefaultInitializableView {
    @State
    var solver = Solver()

    @State
    var lastTime: CFAbsoluteTime?

    @State
    var dt: TimeInterval?

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, _ in
            solver.draw(context: context)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Form {
                LabeledContent("Objects", value: "\(solver.objects.count)")
                if let dt, dt != 0 {
                    LabeledContent("FPS", value: "\(1 / dt, format: .number.precision(.fractionLength(3)))")
                }
                else {
                    LabeledContent("FPS", value: "0")
                }
                LabeledContent("#0", value: "\(solver.objects.first)")
            }
            .padding()
            .background(.regularMaterial)
            .padding()
        }
        .task {
            var frame = 0
            repeat {
                let now = CFAbsoluteTimeGetCurrent()
                if lastTime == nil {
                    lastTime = now
                    continue
                }
                let delta = now - lastTime!
                lastTime = now
                dt = delta

                if solver.objects.count < 2 && frame % 27 == 0 {
                    solver.objects.append(VerletObject(id: solver.objects.count, position_current: [300, 500]))
                    solver.objects.append(VerletObject(id: solver.objects.count, position_current: [400, 500]))
//                    solver.objects.append(VerletObject(id: solver.objects.count, position_current: [500, 500]))
//                    solver.objects.append(VerletObject(id: solver.objects.count, position_current: [600, 500]))
//                    solver.objects.append(VerletObject(id: solver.objects.count, position_current: [700, 500]))
                }
                solver.update(Float(delta))
                try? await Task.sleep(for: .seconds(1.0 / 60.0))
                frame += 1
            }
            while (!Task.isCancelled)
        }
    }
}
