import CoreGraphics
import Foundation
import Geometry

public enum TurtleError: Error {
    case compilationError(String)
}

// MARK: -

public enum TurtleCommand {
    case penDown
    case penUp
    case forward(Double)
    case leftTurn(Double)
    case rightTurn(Double)
    case `repeat`(Int, Program)
}

public struct Program {
    public let commands: [TurtleCommand]

    public init(commands: [TurtleCommand]) {
        self.commands = commands
    }

    public static func compile(source: String) throws -> Program {
        let atoms: [String] = source.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
        return try compile(source: atoms)
    }

    public static func compile(source: [String]) throws -> Program {
        var commands: [TurtleCommand] = []
        var cursor = Cursor(source.makeIterator())
        while cursor.next() != nil {
            let current = cursor.current!
            guard let chomper = chompers[current] else {
                throw TurtleError.compilationError("Could not get chomper for \(current).")
            }
            let command = try chomper(&cursor)
            commands.append(command)
        }
        return Program(commands: commands)
    }
}

extension Program: CustomStringConvertible {
    public var description: String {
        "\(commands)"
    }
}

extension Cursor where Iterator.Element == String {
    mutating func nextDouble() throws -> Double {
        guard let value = next() else {
            throw TurtleError.compilationError("Could not get a value")
        }
        guard let double = Double(value) else {
            throw TurtleError.compilationError("COuld not convert value to a Double")
        }
        return double
    }

    mutating func nextInt() throws -> Int {
        guard let value = next() else {
            throw TurtleError.compilationError("Could not get a value")
        }
        guard let int = Int(value) else {
            throw TurtleError.compilationError("COuld not convert value to a Int")
        }
        return int
    }
}

typealias Chomp = (inout Cursor<IndexingIterator<[String]>>) throws -> TurtleCommand

func repeatChomper(_ cursor: inout Cursor<IndexingIterator<[String]>>) throws -> TurtleCommand {
    let count = try cursor.nextInt()
    guard cursor.next() == "[" else {
        throw TurtleError.compilationError("No [ after repeat")
    }
    var source: [String] = []
    while cursor.next() != nil {
        let current = cursor.current!
        if current == "]" {
            _ = cursor.next()
            return try .repeat(count, Program.compile(source: source))
        }
        source.append(current)
    }
    throw TurtleError.compilationError("Didn't find ]")
}

let chompers: [String: Chomp] = [
    "pd": { _ in .penDown },
    "pu": { _ in .penUp },
    "lt": { cursor in
        let angle = try cursor.nextDouble()
        return .leftTurn(angle)
    },
    "rt": { cursor in
        let angle = try cursor.nextDouble()
        return .rightTurn(angle)
    },
    "fd": { cursor in
        let distance = try cursor.nextDouble()
        return .forward(distance)
    },
    "bk": { cursor in
        let distance = try cursor.nextDouble()
        return .forward(-distance)
    },
    "repeat": repeatChomper,
]

public enum Pen {
    case down
    case up
}

// MARK: Turtle

public protocol TurtleCanvasProtocol {
    func drawLine(start: CGPoint, end: CGPoint)
}

public class Turtle {
    public private(set) var position: CGPoint = .zero
    public private(set) var angle: Double = 0
    public private(set) var pen: Pen = .down
    public let canvas: TurtleCanvasProtocol

    public init(canvas: TurtleCanvasProtocol) {
        self.canvas = canvas
    }

    public func run(program: Program) {
        for command in program.commands {
            process(command: command)
        }
    }

    private func process(command: TurtleCommand) {
        switch command {
        case .penDown:
            pen = .down
        case .penUp:
            pen = .up
        case .forward(let distance):
            let newPosition = position + CGPoint(length: CGPoint.Factor(distance), angle: CGPoint.Factor(angle))
            if pen == .down {
                canvas.drawLine(start: position, end: newPosition)
            }
            position = newPosition
        case .leftTurn(let angle):
            self.angle += degreesToRadians(angle)
        case .rightTurn(let angle):
            self.angle -= degreesToRadians(angle)
        case .repeat(let count, let program):
            for _ in 0 ..< count {
                run(program: program)
            }
        }
    }
}

public struct NilCanvas: TurtleCanvasProtocol {
    public func drawLine(start: CGPoint, end: CGPoint) {
    }
}

public class PathCanvas: TurtleCanvasProtocol {
    public private(set) var path: CGMutablePath!

    public init() {
    }

    public func drawLine(start: CGPoint, end: CGPoint) {
        if path == nil {
            path = CGMutablePath()
            path.move(to: start)
        }
        path.addLines(between: [start, end])
    }
}

struct Cursor<Iterator: IteratorProtocol>: IteratorProtocol {
    private(set) var iterator: Iterator
    private(set) var current: Iterator.Element?

    init(_ iterator: Iterator) {
        self.iterator = iterator
    }

    mutating func next() -> Iterator.Element? {
        current = iterator.next()
        return current
    }

    mutating func advance() {
        current = iterator.next()
    }
}
