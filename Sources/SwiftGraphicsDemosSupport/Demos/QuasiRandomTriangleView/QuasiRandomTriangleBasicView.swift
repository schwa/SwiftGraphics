import Shapes2D
import SwiftUI

struct TriangleReflectionView: View, DemoView {
    @State private var triangle = Triangle(
        a: CGPoint(x: 100, y: 50),
        b: CGPoint(x: 50, y: 150),
        c: CGPoint(x: 150, y: 150)
    )
    @State private var extraPoint = CGPoint(x: 100, y: 100)

    var parallelogram: Parallelogram {
        Parallelogram(triangle: triangle)
    }

    var reflectedPoint: CGPoint {
        parallelogram.reflectedPoint(from: extraPoint)
    }

    var body: some View {
        GeometryReader { _ in
            Canvas { context, _ in
                let parallelogramPath = Path { path in
                    path.move(to: triangle.a)
                    path.addLine(to: triangle.b)
                    path.addLine(to: triangle.c)
                    path.addLine(to: parallelogram.opposite)
                    path.closeSubpath()
                }

                let trianglePath = Path { path in
                    path.move(to: triangle.a)
                    path.addLine(to: triangle.b)
                    path.addLine(to: triangle.c)
                    path.closeSubpath()
                }

                context.stroke(parallelogramPath, with: .color(.blue), lineWidth: 2)
                context.stroke(trianglePath, with: .color(.red), lineWidth: 2)

                let reflectionPath = Path { path in
                    path.move(to: extraPoint)
                    path.addLine(to: reflectedPoint)
                }

                context.stroke(reflectionPath, with: .color(.green), lineWidth: 1)
            }
            .overlay(
                Circle()
                    .fill(Color.black)
                    .frame(width: 10, height: 10)
                    .position(triangle.a)
                    .gesture(DragGesture().onChanged { value in
                        triangle.a = value.location
                    })
            )
            .overlay(
                Circle()
                    .fill(Color.black)
                    .frame(width: 10, height: 10)
                    .position(triangle.b)
                    .gesture(DragGesture().onChanged { value in
                        triangle.b = value.location
                    })
            )
            .overlay(
                Circle()
                    .fill(Color.black)
                    .frame(width: 10, height: 10)
                    .position(triangle.c)
                    .gesture(DragGesture().onChanged { value in
                        triangle.c = value.location
                    })
            )
            .overlay(
                Circle()
                    .fill(Color.purple)
                    .frame(width: 10, height: 10)
                    .position(extraPoint)
                    .gesture(DragGesture().onChanged { value in
                        extraPoint = value.location
                    })
            )
            .overlay(
                Circle()
                    .fill(Color.orange)
                    .frame(width: 10, height: 10)
                    .position(reflectedPoint)
            )
        }
    }
}
