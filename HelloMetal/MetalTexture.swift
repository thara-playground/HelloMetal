//
//  MetalTexture.swift
//  HelloMetal
//
//  Created by Tomochika Hara on 2016/01/03.
//  Copyright © 2016年 Tomochika Hara. All rights reserved.
//

import Foundation
import UIKit


class MetalTexture: NSObject {
    
    var texture: MTLTexture!
    var target: MTLTextureType!
    var width: Int!
    var height: Int!
    var depth: Int!
    var format: MTLPixelFormat!
    var hasAlpha: Bool!
    var path: String!
    var isMipmaped: Bool!
    let bytesPerPixel:Int! = 4
    let bitsPerComponent:Int! = 8
    
    //MARK: - Creation
    init(resourceName: String, ext: String, mipmaped: Bool){
        
        self.path = Bundle.main.path(forResource: resourceName, ofType: ext)
        self.width    = 0
        self.height   = 0
        self.depth    = 1
        self.format   = MTLPixelFormat.rgba8Unorm
        self.target   = MTLTextureType.type2D
        self.texture  = nil
        self.isMipmaped = mipmaped
        
        super.init()
    }
    
    func loadTexture(device: MTLDevice, commandQ: MTLCommandQueue, flip: Bool){
        
        let image = UIImage(contentsOfFile: path)?.cgImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        self.width = image!.width
        self.height = image!.height
        
        let rowBytes = self.width * self.bytesPerPixel
        
        let context = CGContext(data: nil, width: self.width, height: self.height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        let bounds = CGRect(x: 0, y: 0, width: Int(self.width), height: Int(self.height))
        context!.clear(bounds)
        
        if flip == false{
            context!.translateBy(x: 0, y: CGFloat(self.height))
            context!.scaleBy(x: 1.0, y: -1.0)
        }
        
        context?.draw(image!, in: bounds)
        
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm, width: Int(self.width), height: Int(self.height), mipmapped: self.isMipmaped)
        self.target = texDescriptor.textureType
        self.texture = device.makeTexture(descriptor: texDescriptor)
        
        let pixelsData = context!.data
        let region = MTLRegionMake2D(0, 0, Int(self.width), Int(self.height))
        self.texture.replace(region: region, mipmapLevel: 0, withBytes: pixelsData!, bytesPerRow: Int(rowBytes))
        
        if (self.isMipmaped == true){
            self.generateMipMapLayersUsingSystemFunc(texture: texture, device: device, commandQ: commandQ, block: { (buffer) -> Void in
                print("mips generated")
            })
        }
        
        print("mipCount:\(texture.mipmapLevelCount)")
    }
    
    
    
    class func textureCopy(source: MTLTexture,device: MTLDevice, mipmaped: Bool) -> MTLTexture {
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: Int(source.width), height: Int(source.height), mipmapped: mipmaped)
        let copyTexture = device.makeTexture(descriptor: texDescriptor)
        
        
        let region = MTLRegionMake2D(0, 0, Int(source.width), Int(source.height))
        let pixelsData = malloc(source.width * source.height * 4)
        source.getBytes(pixelsData!, bytesPerRow: Int(source.width) * 4, from: region, mipmapLevel: 0)
        copyTexture?.replace(region: region, mipmapLevel: 0, withBytes: pixelsData!, bytesPerRow: Int(source.width) * 4)
        return copyTexture!
    }
    
    class func copyMipLayer(source: MTLTexture, destination:MTLTexture, mipLvl: Int){
        let q = Int(powf(2, Float(mipLvl)))
        let mipmapedWidth = max(Int(source.width)/q,1)
        let mipmapedHeight = max(Int(source.height)/q,1)
        
        let region = MTLRegionMake2D(0, 0, mipmapedWidth, mipmapedHeight)
        let pixelsData = malloc(mipmapedHeight * mipmapedWidth * 4)
        source.getBytes(pixelsData!, bytesPerRow: mipmapedWidth * 4, from: region, mipmapLevel: mipLvl)
        destination.replace(region: region, mipmapLevel: mipLvl, withBytes: pixelsData!, bytesPerRow: mipmapedWidth * 4)
        free(pixelsData)
    }
    
    //MARK: - Generating UIImage from texture mip layers
    func image(mipLevel: Int) -> UIImage{
        
        let p = self.bytesForMipLevel(mipLevel: mipLevel)
        let q = Int(powf(2, Float(mipLevel)))
        let mipmapedWidth = max(self.width / q,1)
        let mipmapedHeight = max(self.height / q,1)
        let rowBytes = mipmapedWidth * 4
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: p, width: mipmapedWidth, height: mipmapedHeight, bitsPerComponent: 8, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        let imgRef = context!.makeImage()
        let image = UIImage(cgImage: imgRef!)
        return image
    }
    
    func image() -> UIImage{
        return self.image(mipLevel: 0)
    }
    
    //MARK: - Getting raw bytes from texture mip layers
    func bytesForMipLevel(mipLevel: Int) -> UnsafeMutableRawPointer{
        let q = Int(powf(2, Float(mipLevel)))
        let mipmapedWidth = max(Int(self.width) / q,1)
        let mipmapedHeight = max(Int(self.height) / q,1)
        
        let rowBytes = Int(mipmapedWidth * 4)
        
        let region = MTLRegionMake2D(0, 0, mipmapedWidth, mipmapedHeight)
        let pointer = malloc(rowBytes * mipmapedHeight)
        self.texture.getBytes(pointer!, bytesPerRow: rowBytes, from: region, mipmapLevel: mipLevel)
        return pointer!
    }
    
    func bytes() -> UnsafeMutableRawPointer{
        return self.bytesForMipLevel(mipLevel: 0)
    }
    
    func generateMipMapLayersUsingSystemFunc(texture: MTLTexture, device: MTLDevice, commandQ: MTLCommandQueue,block: @escaping MTLCommandBufferHandler){
        
        let commandBuffer = commandQ.makeCommandBuffer()
        
        commandBuffer?.addCompletedHandler(block)
        
        let blitCommandEncoder = commandBuffer?.makeBlitCommandEncoder()
        
        blitCommandEncoder?.generateMipmaps(for: texture)
        blitCommandEncoder?.endEncoding()
        
        commandBuffer?.commit()
    }
    
}
