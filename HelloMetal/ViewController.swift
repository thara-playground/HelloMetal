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
    
    var objectToDraw: Cube!
    
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    
    var timer: CADisplayLink! = nil
    
    var projectionMatrix: Matrix4!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degreesToRad(85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
        
        self.device = MTLCreateSystemDefaultDevice()
        
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = device
        self.metalLayer.pixelFormat = .BGRA8Unorm
        self.metalLayer.framebufferOnly = true
        self.metalLayer.frame = self.view.layer.frame
        
        self.view.layer.addSublayer(self.metalLayer)
        
        self.objectToDraw = Cube(device: device)
        self.objectToDraw.positionX =  0.0
        self.objectToDraw.positionY =  0.0
        self.objectToDraw.positionZ = -2.0
        self.objectToDraw.rotationZ = Matrix4.degreesToRad(45)
        self.objectToDraw.scale = 0.5
        
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
        let drawable = metalLayer.nextDrawable()!
        self.objectToDraw.render(self.commandQueue, pipelineState: self.pipelineState, drawable: drawable, projectionMatrix: self.projectionMatrix, clearColor: nil)
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

