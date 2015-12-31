//
//  Cube.swift
//  HelloMetal
//
//  Created by Tomochika Hara on 2015/12/31.
//  Copyright © 2015年 Tomochika Hara. All rights reserved.
//

import Foundation
import Metal


class Cube: Node {
    
    init(device: MTLDevice) {
        
        let A = Vertex(x: -0.3, y:   0.3, z:   0.3, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
        let B = Vertex(x: -0.3, y:  -0.3, z:   0.3, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
        let C = Vertex(x:  0.3, y:  -0.3, z:   0.3, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
        let D = Vertex(x:  0.3, y:   0.3, z:   0.3, r:  0.1, g:  0.6, b:  0.4, a:  1.0)
        
        let Q = Vertex(x: -0.3, y:   0.3, z:  -0.3, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
        let R = Vertex(x:  0.3, y:   0.3, z:  -0.3, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
        let S = Vertex(x: -0.3, y:  -0.3, z:  -0.3, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
        let T = Vertex(x:  0.3, y:  -0.3, z:  -0.3, r:  0.1, g:  0.6, b:  0.4, a:  1.0)
        
        let verticesArray: [Vertex] = [
            A,B,C ,A,C,D,   // Front
            R,T,S ,Q,R,S,   // Back
            
            Q,S,B ,Q,B,A,   // Left
            D,C,T ,D,T,R,   // Right
            
            Q,A,D ,Q,D,R,   // Top
            B,S,T ,B,T,C    // Bot
        ]
        
        super.init(name: "Cube", vertices: verticesArray, device: device)
    }
}