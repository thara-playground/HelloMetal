//
//  Vertex.swift
//  HelloMetal
//
//  Created by Tomochika Hara on 2015/12/31.
//  Copyright © 2015年 Tomochika Hara. All rights reserved.
//

import Foundation

struct Vertex {
    
    var x,y,z: Float    // position data
    var r,g,b,a: Float  // color data
    var s,t: Float      // texture coordinates
    
    func floatBuffer() -> [Float] {
        return [self.x, self.y, self.z, self.r, self.g, self.b, self.a, self.s, self.t]
    }
}