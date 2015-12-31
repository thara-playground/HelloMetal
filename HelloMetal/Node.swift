//
//  Node.swift
//  HelloMetal
//
//  Created by Tomochika Hara on 2015/12/31.
//  Copyright © 2015年 Tomochika Hara. All rights reserved.
//

import Foundation
import Metal
import QuartzCore


class Node {
    
    let name: String
    let vertexCount: Int
    
    let vertexBuffer: MTLBuffer
    var uniformBuffer: MTLBuffer?
    
    var device: MTLDevice
    
    var positionX: Float = 0.0
    var positionY: Float = 0.0
    var positionZ: Float = 0.0
    
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float     = 1.0
    
    init(name: String, vertices: [Vertex], device: MTLDevice) {
        var vertexData = [Float]()
        for vertex in vertices {
            vertexData += vertex.floatBuffer()
        }
        
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        self.vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: .CPUCacheModeDefaultCache)
        
        self.name = name
        self.device = device
        self.vertexCount = vertices.count
    }
    
    func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, projectionMatrix: Matrix4, clearColor: MTLClearColor?) {
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .Store
        
        let commandBuffer = commandQueue.commandBuffer()
        
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, atIndex: 0)
        
        let nodeModelMatrix = self.modelMatrix()
        
        self.uniformBuffer = self.device.newBufferWithLength(sizeof(Float) * Matrix4.numberOfElements() * 2, options: .CPUCacheModeDefaultCache)
        let bufferPointer = self.uniformBuffer?.contents()
        memcpy(bufferPointer!, nodeModelMatrix.raw(), sizeof(Float) * Matrix4.numberOfElements())
        memcpy(bufferPointer! + sizeof(Float) * Matrix4.numberOfElements(), projectionMatrix.raw(), sizeof(Float) * Matrix4.numberOfElements())
        
        renderEncoder.setVertexBuffer(self.uniformBuffer, offset: 0, atIndex: 1)
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: self.vertexCount, instanceCount: self.vertexCount / 3)
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }
    
    func modelMatrix() -> Matrix4 {
        let matrix = Matrix4()
        matrix.translate(self.positionX, y: self.positionY, z: self.positionZ)
        matrix.rotateAroundX(self.rotationX, y: self.rotationY, z: self.rotationZ)
        matrix.scale(self.scale, y: self.scale, z: self.scale)
        return matrix
    }
}