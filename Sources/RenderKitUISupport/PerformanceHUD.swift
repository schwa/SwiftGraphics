// import Charts
import RenderKit
import SwiftUI

public struct PerformanceHUD: View {
    let measurements: [GPUCounters.Measurement.Kind: GPUCounters.Measurement]

    public init(measurements: [GPUCounters.Measurement]) {
        self.measurements = .init(uniqueKeysWithValues: measurements.map { ($0.id, $0) })
    }

    public var body: some View {
        HStack {
            if let frameMeasurement = measurements[.frame] {
                ZStack {
                    frameSectorChart()
                    MeasurementView(measurement: frameMeasurement)
                }
                #if os(macOS)
                .frame(width: 128, height: 128)
                #else
                .frame(width: 80, height: 80)
                #endif
            }
            let kinds: [GPUCounters.Measurement.Kind] = [.computeShader, .vertexShader, .fragmentShader]
            ForEach(kinds, id: \.self) { kind in
                if let measurement = measurements[kind] {
                    MeasurementView(measurement: measurement)
                    #if os(macOS)
                    .frame(width: 128, height: 128)
                    #else
                    .frame(width: 80, height: 80)
                    #endif
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    func frameSectorChart() -> some View {
        EmptyView()
        //        if let frameMeasurement = measurements[.frame] {
        //            // This is all so terrible, it's awesome.
        //            let valueKeyPath = \GPUCounters.Measurement.movingAverage.exponentialMovingAverage
        //            let subKinds: [GPUCounters.Measurement.Kind] = [.computeShader, .vertexShader, .fragmentShader]
        //            let totalValue = frameMeasurement[keyPath: valueKeyPath]
        //            let marks = subKinds.map { kind in
        //                guard let measurement = measurements[kind] else {
        //                    return (kind: kind, value: 0.0)
        //                }
        //                return (kind: kind, value: measurement[keyPath: valueKeyPath])
        //            }
        //            let subtotal = marks.map(\.value).reduce(0, +)
        //            let data: [(name: String, color: Color, value: Double)] =
        //                marks.map { kind, value in
        //                    (kind.name, kind.color, value)
        //                }
        //                + [("Remaining", Color.white, totalValue - subtotal)]
        //            Chart(data, id: \.name) { name, color, value in
        //                SectorMark(
        //                    angle: .value(name, value),
        //                    innerRadius: .ratio(0.9),
        //                    angularInset: 1
        //                )
        //                .foregroundStyle(color)
        //                .cornerRadius(4)
        //            }
        //        }
    }

    struct MeasurementView: View {
        // IDEA: Allow user to switch between modes.
        struct Mode: Identifiable {
            var id: String
            var text: (GPUCounters.Measurement) -> Text
        }

        var modes: [Mode] = [
            .init(id: "Exp. MA") { Text($0.movingAverage.exponentialMovingAverage, format: Self.millisecondsStyle) },
            .init(id: "Latest") { Text(Double($0.samples.last?.value ?? 0), format: Self.millisecondsStyle) }
        ]
        var measurement: GPUCounters.Measurement
        static let millisecondsStyle = FloatingPointFormatStyle<Double>.number.scale(1 / 1_000_000).precision(.significantDigits(4))

        @State
        private var currentMode: Mode

        init(measurement: GPUCounters.Measurement) {
            self.currentMode = modes[0]
            self.measurement = measurement
        }

        var body: some View {
            ZStack {
                Circle().fill(measurement.id.color)
                    .scaleEffect(0.85)
                VStack {
                    Text(measurement.id.name)
                        .textCase(.uppercase)
                        .opacity(0.666)
                    #if os(macOS)
                    .font(.system(size: 12))
                    #else
                    .font(.system(size: 10))
                    #endif
                    currentMode.text(measurement)
                        .bold()
                        .monospaced()
                    #if os(macOS)
                    .font(.system(size: 28))
                    #else
                    .font(.system(size: 14))
                    #endif
                    Text(currentMode.id)
                        .opacity(0.666)
                    #if os(macOS)
                    .font(.system(size: 12))
                    #else
                    .font(.system(size: 10))
                    #endif
                }
            }
        }
    }
}

extension GPUCounters.Measurement.Kind {
    var name: String {
        switch self {
        case .frame:
            return "Frame"
        case .computeShader:
            return "Compute"
        case .vertexShader:
            return "Vertex"
        case .fragmentShader:
            return "Fragment"
        }
    }

    var color: Color {
        switch self {
        case .frame:
            return .green
        case .computeShader:
            return .blue
        case .vertexShader:
            return .cyan
        case .fragmentShader:
            return .purple
        }
    }
}
