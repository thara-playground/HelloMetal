//
//  ViewController.swift
//  HelloMetal
//
//  Created by Tomochika Hara on 2015/12/30.
//  Copyright © 2015年 Tomochika Hara. All rights reserved.
//

import UIKit
import Metal
import QuartzCore


class ViewController: UIViewController {
    
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    
    let vertexData:[Float] = [
         0.0,  1.0, 0.0,
        -1.0, -1.0, 0.0,
         1.0, -1.0, 0.0,
    ]
    
    var vertexBuffer: MTLBuffer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    
    var timer: CADisplayLink! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.device = MTLCreateSystemDefaultDevice()
        
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = device
        self.metalLayer.pixelFormat = .BGRA8Unorm
        self.metalLayer.framebufferOnly = true
        self.metalLayer.frame = self.view.layer.frame
        
        self.view.layer.addSublayer(self.metalLayer)
        
        let dataSize = self.vertexData.count * sizeofValue(self.vertexData[0])
        self.vertexBuffer = self.device.newBufferWithBytes(self.vertexData, length: dataSize, options: .CPUCacheModeDefaultCache)
        
        let defaultLibrary = self.device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
        do {
            self.pipelineState = try self.device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
            return;
        }
        
        self.commandQueue = self.device.newCommandQueue()
        
        
        self.timer = CADisplayLink(target: self, selector: Selector("gameloop"))
        self.timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func render() {
        let drawable = self.metalLayer.nextDrawable()!
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        
        let commandBuffer = self.commandQueue.commandBuffer()
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.setRenderPipelineState(self.pipelineState)
        renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }
    
    func gameloop() {
        autoreleasepool {
            self.render()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

