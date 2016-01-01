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


class MySceneViewController: MetalViewController, MetalViewControllerDelegate {
    
    var worldModelMatrix: Matrix4!
    var objectToDraw: Cube!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.worldModelMatrix = Matrix4()
        self.worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        self.worldModelMatrix.rotateAroundX(Matrix4.degreesToRad(25), y: 0.0, z: 0.0)
        
        self.objectToDraw = Cube(device: device)
        self.metalViewControllerDelegate = self
    }
}


//MARK: - MetalViewControllerDelegate
extension MySceneViewController {
    
    func renderObjects(drawable: CAMetalDrawable) {
        self.objectToDraw.render(self.commandQueue, pipelineState: self.pipelineState, drawable: drawable, parentModelViewMatrix: self.worldModelMatrix, projectionMatrix: self.projectionMatrix, clearColor: nil)
    }
    
    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        self.objectToDraw.updateWithDelta(timeSinceLastUpdate)
    }
}