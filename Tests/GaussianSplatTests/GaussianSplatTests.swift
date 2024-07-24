import Foundation
import Metal
@testable import GaussianSplatDemos
@testable import GaussianSplatSupport
import Testing

@Test
func test1() throws {
    let device = MTLCreateSystemDefaultDevice()!
    let url = Bundle.module.url(forResource: "lastchance", withExtension: "splat")!
    let splatCloud = try SplatCloud(device: device, url: url)
    let unsorted = splatCloud.indicesAndDistances.withUnsafeBuffer { buffer in
        Array(buffer)
    }
    #expect(unsorted.contains(where: { $0.index != 0 || $0.key != 0}) == false)
    let pass = GaussianSplatRadixSortComputePass(splats: splatCloud, modelMatrix: .identity, cameraPosition: .zero)
    let state = try pass.computeOnce(device: device)
//    print(state)
    splatCloud.indicesAndDistances.withUnsafeBuffer { buffer in
        for value in buffer[..<10] {
            print(value)
        }
    }
    print("##################")
    state.altBuffer.withUnsafeBuffer { buffer in
        for value in buffer[..<10] {
            print(value)
        }
    }



    //    let indices = sorted.map(\.indices)
//    print(keys[0..<10])
    //print(keys.sorted() == keys)


    print("DONE")
}
