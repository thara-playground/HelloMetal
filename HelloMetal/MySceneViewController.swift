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
    
    let panSensivity: Float = 5.0
    var lastPanLocation: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.worldModelMatrix = Matrix4()
        self.worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        self.worldModelMatrix.rotateAroundX(Matrix4.degrees(toRad: 25), y: 0.0, z: 0.0)
        
        self.objectToDraw = Cube(device: device, commandQueue: self.commandQueue)
        self.metalViewControllerDelegate = self
        
        self.setupGestures()
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

//MARK: - Gesture related
extension MySceneViewController {
    
    func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MySceneViewController.pan(panGesture:)))
        self.view.addGestureRecognizer(pan)
    }
    
    @objc func pan(panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .changed {
            let pointInView = panGesture.location(in: self.view)
            let xDelta = Float((self.lastPanLocation.x - pointInView.x) / self.view.bounds.width) * self.panSensivity
            let yDelta = Float((self.lastPanLocation.y - pointInView.y) / self.view.bounds.height) * self.panSensivity
            
            self.objectToDraw.rotationY -= xDelta
            self.objectToDraw.rotationX -= yDelta
            self.lastPanLocation = pointInView
        } else if panGesture.state == .began {
            self.lastPanLocation = panGesture.location(in: self.view)
        }
    }

}
