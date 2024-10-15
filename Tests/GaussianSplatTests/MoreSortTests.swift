import BaseSupport
import Foundation
@testable import GaussianSplatSupport
import GaussianSplatShaders
import Testing
import Metal
import SIMDSupport

@Test
func moreSortTest1() throws {
    let splats: [SplatC] = [
        SplatC(position: [0, 0, 0]),
        SplatC(position: [0, 0, 1]),
        SplatC(position: [0, 0, 2]),
        SplatC(position: [0, 0, 3]),
        SplatC(position: [0, 0, 4]),
        SplatC(position: [0, 0, 5]),
        SplatC(position: [0, 0, 6]),
        SplatC(position: [0, 0, 7]),
        SplatC(position: [0, 0, 8]),
        SplatC(position: [0, 0, 9]),
    ]
    let indices = try testHelper(splats: splats, camera: .identity, model: .identity)
    #expect(indices == [
        IndexedDistance(index: 0, distance: 0.0),
        IndexedDistance(index: 1, distance: 1.0),
        IndexedDistance(index: 2, distance: 2.0),
        IndexedDistance(index: 3, distance: 3.0),
        IndexedDistance(index: 4, distance: 4.0),
        IndexedDistance(index: 5, distance: 5.0),
        IndexedDistance(index: 6, distance: 6.0),
        IndexedDistance(index: 7, distance: 7.0),
        IndexedDistance(index: 8, distance: 8.0),
        IndexedDistance(index: 9, distance: 9.0),
    ])
}

@Test
func testNegativePositions() throws {
    let splats: [SplatC] = [
        SplatC(position: [0, 0, -5]),
        SplatC(position: [0, 0, 0]),
        SplatC(position: [0, 0, 5]),
        SplatC(position: [0, 0, -10]),
        SplatC(position: [0, 0, 10]),
    ]
    let indices = try testHelper(splats: splats, camera: .identity, model: .identity)
    #expect(indices == [
        IndexedDistance(index: 3, distance: -10.0),
        IndexedDistance(index: 0, distance: -5.0),
        IndexedDistance(index: 1, distance: 0.0),
        IndexedDistance(index: 2, distance: 5.0),
        IndexedDistance(index: 4, distance: 10.0),
    ])
}

@Test
func testSortStability() throws {
    let splats: [SplatC] = [
        SplatC(position: [0, 0, 5]), // Index 0
        SplatC(position: [0, 0, 5]), // Index 1
        SplatC(position: [0, 0, 5]), // Index 2
        SplatC(position: [0, 0, 10]), // Index 3
        SplatC(position: [0, 0, 10]), // Index 4
    ]
    let indices = try testHelper(splats: splats, camera: .identity, model: .identity)
    #expect(indices == [
        IndexedDistance(index: 0, distance: 5.0),
        IndexedDistance(index: 1, distance: 5.0),
        IndexedDistance(index: 2, distance: 5.0),
        IndexedDistance(index: 3, distance: 10.0),
        IndexedDistance(index: 4, distance: 10.0),
    ])
}
@Test
func testRandomOrderSplats() throws {
    let splats: [SplatC] = [
        SplatC(position: [0, 0, 7]),
        SplatC(position: [0, 0, 2]),
        SplatC(position: [0, 0, 5]),
        SplatC(position: [0, 0, 1]),
        SplatC(position: [0, 0, 9]),
    ]
    let indices = try testHelper(splats: splats, camera: .identity, model: .identity)
    #expect(indices == [
        IndexedDistance(index: 3, distance: 1.0),
        IndexedDistance(index: 1, distance: 2.0),
        IndexedDistance(index: 2, distance: 5.0),
        IndexedDistance(index: 0, distance: 7.0),
        IndexedDistance(index: 4, distance: 9.0),
    ])
}

@Test
func testCameraRotation() throws {
    // Rotate the camera 180 degrees around the Y-axis
    let rotationMatrix = simd_float4x4(SIMD4<Float>(-1, 0, 0, 0),
                                       SIMD4<Float>(0, 1, 0, 0),
                                       SIMD4<Float>(0, 0, -1, 0),
                                       SIMD4<Float>(0, 0, 0, 1))
    let camera = rotationMatrix
    let splats: [SplatC] = [
        SplatC(position: [0, 0, 5]),
        SplatC(position: [0, 0, -5]),
        SplatC(position: [0, 0, 0]),
    ]
    let indices = try testHelper(splats: splats, camera: camera, model: .identity)
    #expect(indices == [
        IndexedDistance(index: 0, distance: -5.0),
        IndexedDistance(index: 2, distance: 0.0),
        IndexedDistance(index: 1, distance: 5.0),
    ])
}

// MARK: -

func testHelper(splats: [SplatC], camera: simd_float4x4, model: simd_float4x4) throws -> [IndexedDistance] {
    let device = MTLCreateSystemDefaultDevice()!
    let splats = try device.makeTypedBuffer(data: splats)
    let sorter = CPUSplatRadixSorter<SplatC>(device: device, capacity: splats.capacity)
    let indices: [IndexedDistance] = try sorter.sort(splats: splats, camera: camera, model: model).toArray()
    return indices
}

/*
 struct IndexedDistance {
     unsigned int index;
     float distance;
 };

 */

extension SplatC {
    init(position: PackedHalf3) {
        self = .init(position: position, color: [0, 0, 0, 0], cov_a: [0, 0, 0], cov_b: [0, 0, 0])
    }
}
