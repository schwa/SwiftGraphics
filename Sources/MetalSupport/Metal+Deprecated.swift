//
//  File 2.swift
//  
//
//  Created by Jonathan Wight on 9/16/23.
//

import Metal

public extension MTLComputeCommandEncoder {
    @available(*, deprecated, message: "RawRepresentable variants are deprecated")
    func setBuffer<T>(_ buffer: MTLBuffer?, offset: Int, index: T) where T: RawRepresentable, T.RawValue == Int {
        setBuffer(buffer, offset: offset, index: index.rawValue)
    }

    @available(*, deprecated, message: "RawRepresentable variants are deprecated")
    func setBytes<T>(_ bytes: UnsafeRawPointer, length: Int, index: T) where T: RawRepresentable, T.RawValue == Int {
        setBytes(bytes, length: length, index: index.rawValue)
    }

    @available(*, deprecated, message: "RawRepresentable variants are deprecated")
    func setTexture<T>(_ texture: MTLTexture?, index: T) where T: RawRepresentable, T.RawValue == Int {
        setTexture(texture, index: index.rawValue)
    }
}

public extension MTLRenderCommandEncoder {
    @available(*, deprecated, message: "RawRepresentable variants are deprecated")
    func setFragmentBuffer<T>(_ buffer: MTLBuffer?, offset: Int, index: T) where T: RawRepresentable, T.RawValue == Int {
        setFragmentBuffer(buffer, offset: offset, index: index.rawValue)
    }

    @available(*, deprecated, message: "RawRepresentable variants are deprecated")
    func setVertexTexture<T>(_ texture: MTLTexture?, index: T) where T: RawRepresentable, T.RawValue == Int {
        setVertexTexture(texture, index: index.rawValue)
    }

    @available(*, deprecated, message: "RawRepresentable variants are deprecated")
    func setFragmentTexture<T>(_ texture: MTLTexture?, index: T) where T: RawRepresentable, T.RawValue == Int {
        setFragmentTexture(texture, index: index.rawValue)
    }

    @available(*, deprecated, message: "RawRepresentable variants are deprecated")
    func setVertexBuffer<T>(_ buffer: MTLBuffer?, offset: Int, index: T) where T: RawRepresentable, T.RawValue == Int {
        setVertexBuffer(buffer, offset: offset, index: index.rawValue)
    }

    @available(*, deprecated, message: "MTLRenderStage variants are deprecated")
    func setBuffer(_ buffer: MTLBuffer?, offset: Int, stage: MTLRenderStages, index: Int) {
        switch stage {
        case .vertex:
            setVertexBuffer(buffer, offset: offset, index: index)
        case .fragment:
            setFragmentBuffer(buffer, offset: offset, index: index)
        default:
            fatalError("Unexpected case")
        }
    }

    @available(*, deprecated, message: "MTLRenderStage variants are deprecated")
    func setBytes(_ bytes: UnsafeRawPointer, length: Int, stage: MTLRenderStages, index: Int) {
        switch stage {
        case .vertex:
            setVertexBytes(bytes, length: length, index: index)
        case .fragment:
            setFragmentBytes(bytes, length: length, index: index)
        default:
            fatalError("Unexpected case")
        }
    }

    @available(*, deprecated, message: "MTLRenderStage variants are deprecated")
    func setBytes(_ buffer: UnsafeRawBufferPointer, stage: MTLRenderStages, index: Int) {
        setBytes(buffer.baseAddress!, length: buffer.count, stage: stage, index: index)
    }

    @available(*, deprecated, message: "MTLRenderStage variants are deprecated")
    func setBytes(of value: some Any, stage: MTLRenderStages, index: Int) {
        withUnsafeBytes(of: value) { (buffer: UnsafeRawBufferPointer) in
            setBytes(buffer, stage: stage, index: index)
        }
    }

    @available(*, deprecated, message: "MTLRenderStage variants are deprecated")
    func setBytes(of array: [some Any], stage: MTLRenderStages, index: Int) {
        array.withUnsafeBytes { buffer in
            setBytes(buffer, stage: stage, index: index)
        }
    }

    @available(*, deprecated, message: "MTLRenderStage variants are deprecated")
    func setTexture(_ value: MTLTexture?, stage: MTLRenderStages, index: Int) {
        switch stage {
        case .vertex:
            setVertexTexture(value, index: index)
        case .fragment:
            setFragmentTexture(value, index: index)
        default:
            fatalError("Unexpected case")
        }
    }

    @available(*, deprecated, message: "MTLRenderStage variants are deprecated")
    func setSamplerState(_ value: MTLSamplerState?, stage: MTLRenderStages, index: Int) {
        switch stage {
        case .vertex:
            setVertexSamplerState(value, index: index)
        case .fragment:
            setFragmentSamplerState(value, index: index)
        default:
            fatalError("Unexpected case")
        }
    }
}
