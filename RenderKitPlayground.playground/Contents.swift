import UIKit
import RenderKitScratch
import simd

let sphere = Sphere(center: .zero, radius: 8)
print(try sphere.encodeToShapeScript())

let line = Line3D(point: [0, 0, 0], direction: [1, 0, 0])

print(try line.encodeToShapeScript())
