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
    
    var avaliableResourcesSemaphore: DispatchSemaphore
    
    init(device: MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {
        
        self.avaliableResourcesSemaphore = DispatchSemaphore(value: inflightBuffersCount)
        
        self.inflightBuffersCount = inflightBuffersCount
        self.uniformsBuffers = [MTLBuffer]()
        
        for _ in 0...self.inflightBuffersCount - 1 {
            let uniformsBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: [])
            uniformsBuffers.append(uniformsBuffer)
        }
    }
    
    func nextUniformsBuffer(projectionMatrix: Matrix4, modelViewMatrix: Matrix4) -> MTLBuffer {
        let buffer = self.uniformsBuffers[self.avaliableBufferIndex]
        let bufferPointer = buffer.contents()
        
        memcpy(bufferPointer, modelViewMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        memcpy(bufferPointer + MemoryLayout<Float>.size * Matrix4.numberOfElements(), projectionMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        
        self.avaliableBufferIndex += 1
        if avaliableBufferIndex == self.inflightBuffersCount {
            self.avaliableBufferIndex = 0
        }
        return buffer
    }
    
    deinit {
        for _ in 0...self.inflightBuffersCount {
            self.avaliableResourcesSemaphore.signal()
        }
    }
}
