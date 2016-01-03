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
        
        self.projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degreesToRad(85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
        
        self.device = MTLCreateSystemDefaultDevice()
        
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = device
        self.metalLayer.pixelFormat = .BGRA8Unorm
        self.metalLayer.framebufferOnly = true
        self.view.layer.addSublayer(self.metalLayer)
        
        self.commandQueue = device.newCommandQueue()
        
        let defaultLibrary = self.device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .Add;
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .Add;
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .One;
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .One;
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .OneMinusSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .OneMinusSourceAlpha;

        self.pipelineState = try! self.device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        
        self.timer = CADisplayLink(target: self, selector: Selector("newFrame:"))
        self.timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
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
        self.projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degreesToRad(85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
    }
    
    func render() {
        if let drawable = metalLayer.nextDrawable() {
            self.metalViewControllerDelegate?.renderObjects(drawable)
        }
    }
    
    func newFrame(displayLink: CADisplayLink) {
        if self.lastFrameTimestamp == 0.0 {
            self.lastFrameTimestamp = displayLink.timestamp
        }
        
        let elapsed: CFTimeInterval = displayLink.timestamp - self.lastFrameTimestamp
        self.lastFrameTimestamp = displayLink.timestamp
        
        self.gameloop(timeSinceLastUpdate: elapsed)
    }
    
    func gameloop(timeSinceLastUpdate timeSinceLastUpdate: CFTimeInterval) {
        
        self.metalViewControllerDelegate?.updateLogic(timeSinceLastUpdate)
        
        autoreleasepool {
            self.render()
        }
    }
}