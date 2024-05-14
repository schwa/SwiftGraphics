import Metal
import MetalKit
import ModelIO
import Observation
import RenderKit
import RenderKitShaders
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct SimulationView: View, DefaultInitializableView {
    @State
    var simulation: Simulation<ArraySimulatorStorage>

    @State
    var mouseLocation: CGPoint?

    let gradient = MyGradient(colors: [
        [0, 0, 1, 0.5],
        [1, 0, 0, 0.5],
    ])

    @State
    var renderRadius: Double = 5

    @State
    var blurRadius: Double = 0

    @State
    var scale: Double = 1

    @State
    var blendMode: GraphicsContext.BlendMode = .screen

    public init() {
        let count = 500
        let storage = ArraySimulatorStorage(positions: Array(repeating: .zero, count: count), velocities: Array(repeating: .zero, count: count), densities: Array(repeating: .zero, count: count))
        simulation = Simulation(count: count, storage: storage, size: .zero)
    }

    public var body: some View {
        VStack {
            GeometryReader { proxy in
                TimelineView(.animation) { context in
                    ZStack {
                        let time = context.date.timeIntervalSince1970
                        Canvas { context, size in
                            context.blendMode = blendMode
                            simulation.step(time: time)
                            draw(context: context, size: size)
                        }
                        .background(Color.black)
                        .blur(radius: blurRadius)
                        Canvas { context, _ in
                            var indicesNearMouse: Set<Int> = []
                            if let mouseLocation {
                                simulation.table.indicesNear(point: SIMD2<Float>(mouseLocation)) { index in
                                    indicesNearMouse.insert(index)
                                }
                                let path = Path(ellipseIn: CGRect(center: mouseLocation, radius: Double(simulation.table.radius)))
                                context.fill(path, with: .color(.black.opacity(0.1)))
                                for i in indicesNearMouse {
                                    let position = simulation.storage.positions[i]
                                    let path = Path(ellipseIn: CGRect(center: CGPoint(position), radius: CGFloat(simulation.particleRadius)))
                                    context.fill(path, with: .color(.red))
                                }
                            }
                        }
                    }
                    .clipped()
                }
                .onAppear {
                    simulation.size = proxy.size
                    simulation.populate()
                }
            }
            .frame(width: 1_000, height: 500)
            .padding()
            HStack {
                config()
                    .frame(width: 640)
                statistics()
                    .frame(width: 320)
            }
        }
        .gesture(DragGesture().onChanged({ value in
            mouseLocation = value.location
            let location = SIMD2<Float>(value.location)
            for index in 0 ..< simulation.count {
                let force = location - simulation.storage.positions[index]
                // simulation.storage.positions[index] / location
                simulation.storage.velocities[index] += (1 / force) * 50
            }
        }))
        .onContinuousHover(coordinateSpace: .local) { phase in
            switch phase {
            case .active(let location):
                mouseLocation = location
            case .ended:
                mouseLocation = nil
            }
        }
    }

    func draw(context: GraphicsContext, size: CGSize) {
        for index in 0 ..< simulation.count {
            let position = simulation.storage.positions[index]
            let density = simulation.storage.densities[index]
            let velocity = simulation.storage.velocities[index]
            let speed = velocity.magnitude
            var normalizedDensity = inverseLerp(value: density, startValue: simulation.statistics.minDensity, endValue: simulation.statistics.maxDensity)
            if normalizedDensity.isNaN {
                normalizedDensity = simulation.statistics.minDensity
            }
            var normalizedSpeed = inverseLerp(value: speed, startValue: simulation.statistics.minSpeed, endValue: simulation.statistics.maxSpeed)
            if normalizedSpeed.isNaN {
                normalizedSpeed = simulation.statistics.minSpeed
            }
            var color: Color = .red
            if !normalizedSpeed.isNaN {
                color = Color(gradient.color(at: normalizedDensity))
                // color = Color(hue: 0, saturation: 1, brightness: Double(normalizedSpeed))
            }
            let path = Path(ellipseIn: CGRect(center: CGPoint(position), radius: CGFloat(renderRadius)))
            context.fill(path, with: .color(color))
        }
    }

    func config() -> some View {
        HStack {
            Form {
                Section("Simulation") {
                    TextField("Size", value: $simulation.size, format: .size)
                    TextField("Smoothing Radius", value: $simulation.smoothingRadius, format: .number)
                    TextField("Gravity", value: $simulation.gravity, format: .vector)
                    TextField("collisionDampingFactor", value: $simulation.collisionDampingFactor, format: .number)
                    TextField("mass", value: $simulation.mass, format: .number)
                    TextField("Radius", value: $simulation.particleRadius, format: .number)
                    TextField("targetDensity", value: $simulation.targetDensity, format: .number)
                    TextField("pressureMultiplier", value: $simulation.pressureMultiplier, format: .number)
                    TextField("speed", value: $simulation.speed, format: .number)
                    Toggle(isOn: $simulation.enablePressure) {
                        Text("Enable Pressure")
                    }
                }
            }
            Form {
                Section("Render") {
                    TextField("Radius", value: $renderRadius, format: .number)
                    TextField("Blur Radius", value: $blurRadius, format: .number)
                    Picker("Blend Mode", selection: $blendMode) {
                        ForEach(GraphicsContext.BlendMode.allCases, id: \.self) { blendMode in
                            Text(blendMode.description).tag(blendMode)
                        }
                    }
                }
            }
        }
    }

    func statistics() -> some View {
        Form {
            TimelineView(.animation) { _ in
                LabeledContent("Count", value: "\(simulation.count, format: .number)")
                LabeledContent("Step", value: "\(simulation.step, format: .number)")
                LabeledContent("LastTime", value: "\(simulation.lastTime ?? 0, format: .number)")
                LabeledContent("Min Speed", value: "\(simulation.statistics.minSpeed, format: .number)")
                LabeledContent("Max Speed", value: "\(simulation.statistics.maxSpeed, format: .number)")
                LabeledContent("Mean Speed", value: "\(simulation.statistics.averageSpeed, format: .number)")
                LabeledContent("Min Density", value: "\(simulation.statistics.minDensity, format: .number)")
                LabeledContent("Max Density", value: "\(simulation.statistics.maxDensity, format: .number)")
                LabeledContent("Mean Density", value: "\(simulation.statistics.averageDensity, format: .number)")
            }
        }
    }
}

extension GraphicsContext.BlendMode: Hashable {
}

extension GraphicsContext.BlendMode: CaseIterable {
    public static var allCases: [GraphicsContext.BlendMode] {
        [
            .normal,
            .multiply,
            .screen,
            .overlay,
            .darken,
            .lighten,
            .colorDodge,
            .colorBurn,
            .softLight,
            .hardLight,
            .difference,
            .exclusion,
            .hue,
            .saturation,
            .color,
            .luminosity,
            .clear,
            .copy,
            .sourceIn,
            .sourceOut,
            .sourceAtop,
            .destinationOver,
            .destinationIn,
            .destinationOut,
            .destinationAtop,
            .xor,
            .plusDarker,
            .plusLighter,
        ]
    }
}

extension GraphicsContext.BlendMode: CustomStringConvertible {
    public var description: String {
        // swiftlint:disable switch_case_on_newline
        switch self {
        case .normal: "normal"
        case .multiply: "multiply"
        case .screen: "screen"
        case .overlay: "overlay"
        case .darken: "darken"
        case .lighten: "lighten"
        case .colorDodge: "colorDodge"
        case .colorBurn: "colorBurn"
        case .softLight: "softLight"
        case .hardLight: "hardLight"
        case .difference: "difference"
        case .exclusion: "exclusion"
        case .hue: "hue"
        case .saturation: "saturation"
        case .color: "color"
        case .luminosity: "luminosity"
        case .clear: "clear"
        case .copy: "copy"
        case .sourceIn: "sourceIn"
        case .sourceOut: "sourceOut"
        case .sourceAtop: "sourceAtop"
        case .destinationOver: "destinationOver"
        case .destinationIn: "destinationIn"
        case .destinationOut: "destinationOut"
        case .destinationAtop: "destinationAtop"
        case .xor: "xor"
        case .plusDarker: "plusDarker"
        case .plusLighter: "plusLighter"
        default:
            fatalError()
        }
    }
}
