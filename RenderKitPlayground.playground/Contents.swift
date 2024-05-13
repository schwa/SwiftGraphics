import RenderKitScratch
import simd
import UIKit

let sphere = Sphere(center: .zero, radius: 8)
try print(sphere.encodeToShapeScript())

let line = Line3D(point: [0, 0, 0], direction: [1, 0, 0])

try print(line.encodeToShapeScript())
