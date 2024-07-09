import simd
import SwiftUI

struct MyGradient {
    struct Stop {
        var color: SIMD4<Float>
        var location: Float
        var controls: (Float, Float, Float) = (0, 0, 0)
    }

    var stops: [Stop]

    init(stops: [Stop]) {
        if stops.count == 1 {
            self.stops = stops
            return
        }
        assert(stops.first?.location == 0)
        assert(stops.last?.location == 1)
        self.stops = stops.enumerated().map { index, stop in
            var handle: (Float, Float, Float) = (stop.location, stop.location, stop.location)
            if index != 0 {
                handle.0 = stops[index - 1].location
            }
            if index != stops.count - 1 {
                handle.2 = stops[index + 1].location
            }
            var stop = stop
            stop.controls = handle
            return (stop)
        }
    }
}

extension MyGradient {
    init(colors: [SIMD4<Float>]) {
        let delta = 1 / Float(colors.count - 1)
        self = .init(stops: colors.enumerated().map { index, color in
            Stop(color: color, location: Float(index) * delta)
        })
    }
}

extension MyGradient {
    func color(at position: Float) -> SIMD4<Float> {
        if stops.count == 1 {
            return stops.first!.color
        }
        return stops.reduce(SIMD4<Float>.zero) { result, stop in
            var factor: Float = 0
            if (stop.controls.0 ... stop.controls.1).contains(position) {
                factor = inverseLerp(value: position, startValue: stop.controls.0, endValue: stop.controls.1)
            }
            else if (stop.controls.1 ... stop.controls.2).contains(position) {
                factor = 1 - inverseLerp(value: position, startValue: stop.controls.1, endValue: stop.controls.2)
            }
            let color = stop.color * factor
            return result + color
        }
    }
}

// func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
//    let max_ = max(value, lower)
//    let min_ = min(max_, upper)
//    return min_
// }

func inverseLerp(value: Float, startValue: Float, endValue: Float) -> Float {
    let result: Float
    //    if value <= startValue {
    //        result = 0
    //    }
    //    else if value >= endValue {
    //        result = 0
    //    }
    //    else {
    result = (value - startValue) / (endValue - startValue)
    //    }
    return result
}

extension Color {
    init(_ color: SIMD4<Float>) {
        self = Color(red: Double(color[0]), green: Double(color[1]), blue: Double(color[2]))
    }
}
