//
//  BufferProvider.swift
//  HelloMetal
//
//  Created by Tomochika Hara on 2016/01/01.
//  Copyright © 2016年 Tomochika Hara. All rights reserved.
//

import Foundation
import Metal


class BufferProvider: NSObject {
    
    let inflightBuffersCount: Int
    private var uniformsBuffers: [MTLBuffer]
    private var avaliableBufferIndex: Int = 0
    
    init(device: MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {
        
        self.inflightBuffersCount = inflightBuffersCount
        self.uniformsBuffers = [MTLBuffer]()
        
        for _ in 0...self.inflightBuffersCount - 1 {
            let uniformsBuffer = device.newBufferWithLength(sizeOfUniformsBuffer, options: .CPUCacheModeDefaultCache)
            uniformsBuffers.append(uniformsBuffer)
        }
    }
    
    func nextUniformsBuffer(projectionMatrix: Matrix4, modelViewMatrix: Matrix4) -> MTLBuffer {
        let buffer = self.uniformsBuffers[self.avaliableBufferIndex]
        let bufferPointer = buffer.contents()
        
        memcpy(bufferPointer, modelViewMatrix.raw(), sizeof(Float) * Matrix4.numberOfElements())
        memcpy(bufferPointer + sizeof(Float) * Matrix4.numberOfElements(), projectionMatrix.raw(), sizeof(Float) * Matrix4.numberOfElements())
        
        self.avaliableBufferIndex++
        if avaliableBufferIndex == self.inflightBuffersCount {
            self.avaliableBufferIndex = 0
        }
        return buffer
    }
}