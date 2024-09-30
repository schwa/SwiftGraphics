import Foundation
import Metal
import MetalSupport
@testable import GaussianSplatSupport
import GaussianSplatShaders
import Testing

// TODO: FIXME currently failing to load shaders.
//@Test(.disabled())
//func test1() throws {
//    let device = MTLCreateSystemDefaultDevice()!
//    let url = Bundle.module.url(forResource: "lastchance", withExtension: "splat")!
//
//    // Make sure our loaded splat cloud is at least initialized correct.
//    let splatCloud = try SplatCloud<SplatC>(device: device, url: url)
//    let blank = splatCloud.indexedDistances.offscreen.toArray()
//    #expect(blank.allSatisfy { $0.distance == 0 })
//    #expect(blank.enumerated().allSatisfy { UInt32($0) == $1.index })
//
//    // Get distances for all splats on the GPU and make sure we have distance info for every splat.
//    let distancePass = GaussianSplatDistanceComputePass<SplatC>(id: "Distance", splats: splatCloud, modelMatrix: .identity, cameraPosition: .zero)
//    try distancePass.computeOnce(device: device)
//    let unsorted = splatCloud.indexedDistances.offscreen.toArray()
//    #expect(unsorted.contains(where: { $0.distance != 0 }))
//    #expect(unsorted.allSatisfy { $0.distance != 0 })
//    #expect(unsorted.enumerated().allSatisfy { UInt32($0) == $1.index })
//
//    // Do a GPU based sort
//    let sortPass = GaussianSplatBitonicSortComputePass<SplatC>(id: "Sort", splats: splatCloud)
//    try sortPass.computeOnce(device: device)
//    let sorted = splatCloud.indexedDistances.offscreen.toArray()
//
//    // Because GPU sort is stable indices may be in different order for same distances. Only compare distance.
//    let cpuSorted = Array(unsorted.sorted(by: \.distance).reversed())
//    #expect(sorted.map(\.distance) == cpuSorted.map(\.distance))
//
//    // Make sure our distances and indices are still correct.
//    let expectedIndicesByDistance = Dictionary(uniqueKeysWithValues: unsorted.map({ ($0.index, $0.distance) }))
//    let indicesByDistance = Dictionary(uniqueKeysWithValues: sorted.map({ ($0.index, $0.distance) }))
//    #expect(indicesByDistance == expectedIndicesByDistance)
//
//    // Do a second GPU based sort
//    let sortPassAgain = GaussianSplatBitonicSortComputePass<SplatC>(id: "Sort2", splats: splatCloud)
//    try sortPassAgain.computeOnce(device: device)
//    let sortedAgain = splatCloud.indexedDistances.offscreen.toArray()
//    #expect(sorted == sortedAgain)
//}

extension TypedMTLBuffer {
    func toArray() -> [Element] {
        withUnsafeBufferPointer { buffer in
            Array(buffer)
        }
    }
}

extension IndexedDistance: @retroactive Equatable {
    public static func == (lhs: IndexedDistance, rhs: IndexedDistance) -> Bool {
        lhs.distance == rhs.distance && lhs.index == rhs.index
    }
}

extension IndexedDistance: @retroactive CustomStringConvertible {
    public var description: String {
        "[\(distance) #\(index)]"
    }
}
