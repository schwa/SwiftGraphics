import SwiftUI

protocol LSystemRecipe {
    associatedtype Symbol where Symbol: Hashable

    var system: LSystem<Symbol> { get }
    func apply<Turtle>(symbol: Symbol, in turtle: inout Turtle) where Turtle: TurtleProtocol
}

// swiftlint:disable:next type_name
struct FractalBinaryTree_: LSystemRecipe {
    let system = LSystem(initialState: "0", rules: [
        "1": "11",
        "0": "1[0]0",
    ])

    func apply<Turtle>(symbol: Symbol, in turtle: inout Turtle) where Turtle: TurtleProtocol {
        let distance = 1.0
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
}

struct FractalBinaryTree: View {
    var distance = 2.0
    var symbols = LSystem.fractalBinaryTree.apply(iterations: 7)

    var body: some View {
        ReplayableCanvas { context, size in
            var turtle = GraphicsContextTurtle(context: context)
            turtle.position = CGPoint(x: size.width / 2, y: size.height - distance)
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
        }
    }
}

struct SierpinskiTriangle: View {
    let symbols = LSystem.sierpinskiTriangle.apply(iterations: 6)

    var body: some View {
        ReplayableCanvas { context, size in
            let distance = 5.0

            var turtle = GraphicsContextTurtle(context: context)
            turtle.position = CGPoint(x: size.width / 2 - 120, y: size.height / 2 + 120)
            for symbol in symbols {
                switch symbol {
                case "F", "G":
                    turtle.forwards(distance: distance)
                case "-":
                    turtle.turnLeft(angle: .degrees(120))
                case "+":
                    turtle.turnRight(angle: .degrees(120))
                default:
                    fatalError("Unrecognised symbol \(symbol)")
                }
            }
        }
    }
}

struct DragonCurve: View {
    let symbols = LSystem.dragonCurve.apply(iterations: 15)

    var body: some View {
        ReplayableCanvas { context, size in
            let distance = 5.0

            var turtle = GraphicsContextTurtle(context: context)
            turtle.position = CGPoint(x: size.width / 2 - 120, y: size.height / 2 + 120)
            for symbol in symbols {
                switch symbol {
                case "F", "G":
                    turtle.forwards(distance: distance)
                case "-":
                    turtle.turnLeft(angle: .degrees(90))
                case "+":
                    turtle.turnRight(angle: .degrees(90))
                default:
                    fatalError("Unrecognised symbol \(symbol)")
                }
            }
        }
    }
}

struct HilbertCurve: View {
    let symbols = LSystem.hilbertCurve.apply(iterations: 10)

    init() {
    }

    var body: some View {
        ReplayableCanvas { context, size in
            let distance = 5.0

            var turtle = GraphicsContextTurtle(context: context)
            turtle.position = CGPoint(x: size.width / 2 - 120, y: size.height / 2 + 120)
            for symbol in symbols {
                switch symbol {
                case "F":
                    turtle.forwards(distance: distance)
                case "-":
                    turtle.turnLeft(angle: .degrees(90))
                case "+":
                    turtle.turnRight(angle: .degrees(90))
                case "A", "B":
                    break
                default:
                    fatalError("Unrecognised symbol \(symbol)")
                }
            }
        }
    }
}

#Preview {
    HilbertCurve()
}
