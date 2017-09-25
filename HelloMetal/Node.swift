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
    
    var device: MTLDevice
    
    var positionX: Float = 0.0
    var positionY: Float = 0.0
    var positionZ: Float = 0.0
    
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float     = 1.0
    
    var time:CFTimeInterval = 0.0
    
    var bufferProvider: BufferProvider
    
    var texture: MTLTexture
    lazy var samplerState: MTLSamplerState? = Node.defaultSampler(device: self.device)
    
    init(name: String, vertices: [Vertex], device: MTLDevice, texture: MTLTexture) {
        var vertexData = [Float]()
        for vertex in vertices {
            vertexData += vertex.floatBuffer()
        }
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        self.vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: MTLResourceOptions())!
        
        self.name = name
        self.device = device
        self.vertexCount = vertices.count
        self.texture = texture
        
        self.bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2)
    }
    
    func render(_ commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: Matrix4, projectionMatrix: Matrix4, clearColor: MTLClearColor?) {
        
        _ = self.bufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.addCompletedHandler { (commandBuffer) -> Void in
            let _ = self.bufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setCullMode(.front)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setFragmentTexture(self.texture, index: 0)
        if let samplerState = self.samplerState {
            renderEncoder?.setFragmentSamplerState(samplerState, index: 0)
        }
        
        let nodeModelMatrix = self.modelMatrix()
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        
        let uniformBuffer = self.bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix, modelViewMatrix: nodeModelMatrix)
        
        renderEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: self.vertexCount, instanceCount: self.vertexCount / 3)
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    func modelMatrix() -> Matrix4 {
        let matrix = Matrix4()
        matrix?.translate(self.positionX, y: self.positionY, z: self.positionZ)
        matrix?.rotateAroundX(self.rotationX, y: self.rotationY, z: self.rotationZ)
        matrix?.scale(self.scale, y: self.scale, z: self.scale)
        return matrix!
    }
    
    func updateWithDelta(_ delta: CFTimeInterval) {
        self.time += delta
    }
    
    class func defaultSampler(device: MTLDevice) -> MTLSamplerState {
        
        let samplerDescriptor: MTLSamplerDescriptor? = MTLSamplerDescriptor()
        
        if let sampler = samplerDescriptor {
            sampler.minFilter = .nearest
            sampler.magFilter = .nearest
            sampler.mipFilter = .nearest
            sampler.maxAnisotropy = 1
            sampler.sAddressMode = .clampToEdge
            sampler.tAddressMode = .clampToEdge
            sampler.rAddressMode = .clampToEdge
            sampler.normalizedCoordinates = true
            sampler.lodMaxClamp = 0
            sampler.lodMaxClamp = Float.greatestFiniteMagnitude
        } else {
            print(">> ERROR: Failed creating a sampler descriptor!")
        }
        
        return device.makeSamplerState(descriptor: samplerDescriptor!)!
    }
}
