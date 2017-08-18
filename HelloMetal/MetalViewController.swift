//
//  MetalViewController.swift
//  HelloMetal
//
//  Created by Tomochika Hara on 2016/01/01.
//  Copyright © 2016年 Tomochika Hara. All rights reserved.
//

import Foundation
import Metal
import QuartzCore


protocol MetalViewControllerDelegate : class{
    func updateLogic(timeSinceLastUpdate:CFTimeInterval)
    func renderObjects(drawable:CAMetalDrawable)
}


class MetalViewController: UIViewController {
    
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    var timer: CADisplayLink! = nil
    var projectionMatrix: Matrix4!
    var lastFrameTimestamp: CFTimeInterval = 0.0
    
    weak var metalViewControllerDelegate: MetalViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
        
        self.device = MTLCreateSystemDefaultDevice()
        
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = device
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = true
        self.view.layer.addSublayer(self.metalLayer)
        
        self.commandQueue = device.makeCommandQueue()
        
        let defaultLibrary = self.device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary!.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add;
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add;
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one;
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one;
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha;

        self.pipelineState = try! self.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        self.timer = CADisplayLink(target: self, selector: #selector(MetalViewController.newFrame(_:)))
        self.timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let window = self.view.window {
            let scale = window.screen.nativeScale
            let layerSize = self.view.bounds.size
            
            self.view.contentScaleFactor = scale
            self.metalLayer.frame = CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height)
            self.metalLayer.drawableSize = CGSize(width: layerSize.width * scale, height: layerSize.height * scale)
        }
        self.projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
    }
    
    func render() {
        if let drawable = metalLayer.nextDrawable() {
            self.metalViewControllerDelegate?.renderObjects(drawable: drawable)
        }
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
        
        self.metalViewControllerDelegate?.updateLogic(timeSinceLastUpdate: timeSinceLastUpdate)
        
        autoreleasepool {
            self.render()
        }
    }
}
