//
//  PackedFloatTests.swift
//  SwiftGraphics
//
//  Created by Jonathan Wight on 7/26/24.
//

import SIMDSupport
import simd
import Testing

@Test
func testPackedFloatSizes() {
    #expect(MemoryLayout<SIMD3<Float>>.size == 16)
    #expect(MemoryLayout<SIMD3<Float>>.stride == 16)
    #expect(MemoryLayout<PackedFloat3>.size == 16)
    #expect(MemoryLayout<PackedFloat3>.stride == 16)
}
