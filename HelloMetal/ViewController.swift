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
    
    var lastFrameTimestamp: CFTimeInterval = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
        
        self.device = MTLCreateSystemDefaultDevice()
        
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = device
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = true
        self.metalLayer.frame = self.view.layer.frame
        
        self.view.layer.addSublayer(self.metalLayer)
        
        self.objectToDraw = Cube(device: device)
        
        let defaultLibrary = self.device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary!.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            self.pipelineState = try self.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
            return;
        }
        
        self.commandQueue = self.device.makeCommandQueue()
        
        
        self.timer = CADisplayLink(target: self, selector: #selector(ViewController.newFrame(_:)))
        self.timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func render() {
        let drawable = metalLayer.nextDrawable()!
        
        let worldModelMatrix = Matrix4()
        worldModelMatrix?.translate(0.0, y: 0.0, z: -7.0)
        worldModelMatrix?.rotateAroundX(Matrix4.degrees(toRad: 25), y: 0.0, z: 0.0)
        
        self.objectToDraw.render(self.commandQueue, pipelineState: self.pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix!, projectionMatrix: self.projectionMatrix, clearColor: nil)
    }
    
    func newFrame(_ displayLink: CADisplayLink) {
        if self.lastFrameTimestamp == 0.0 {
            self.lastFrameTimestamp = displayLink.timestamp
        }
        
        let elapsed: CFTimeInterval = displayLink.timestamp - self.lastFrameTimestamp
        self.lastFrameTimestamp = displayLink.timestamp
        
        self.gameloop(timeSinceLastUpdate: elapsed)
    }
    
    func gameloop(timeSinceLastUpdate: CFTimeInterval) {
        
        self.objectToDraw.updateWithDelta(timeSinceLastUpdate)
        
        autoreleasepool {
            self.render()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

