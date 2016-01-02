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
        
        self.path = NSBundle.mainBundle().pathForResource(resourceName, ofType: ext)
        self.width    = 0
        self.height   = 0
        self.depth    = 1
        self.format   = MTLPixelFormat.RGBA8Unorm
        self.target   = MTLTextureType.Type2D
        self.texture  = nil
        self.isMipmaped = mipmaped
        
        super.init()
    }
    
    func loadTexture(device device: MTLDevice, commandQ: MTLCommandQueue, flip: Bool){
        
        let image = UIImage(contentsOfFile: path)?.CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        self.width = CGImageGetWidth(image)
        self.height = CGImageGetHeight(image)
        
        let rowBytes = self.width * self.bytesPerPixel
        
        let context = CGBitmapContextCreate(nil, self.width, self.height, self.bitsPerComponent, rowBytes, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)
        let bounds = CGRect(x: 0, y: 0, width: Int(self.width), height: Int(self.height))
        CGContextClearRect(context, bounds)
        
        if flip == false{
            CGContextTranslateCTM(context, 0, CGFloat(self.height))
            CGContextScaleCTM(context, 1.0, -1.0)
        }
        
        CGContextDrawImage(context, bounds, image)
        
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: Int(self.width), height: Int(self.height), mipmapped: self.isMipmaped)
        self.target = texDescriptor.textureType
        self.texture = device.newTextureWithDescriptor(texDescriptor)
        
        let pixelsData = CGBitmapContextGetData(context)
        let region = MTLRegionMake2D(0, 0, Int(self.width), Int(self.height))
        self.texture.replaceRegion(region, mipmapLevel: 0, withBytes: pixelsData, bytesPerRow: Int(rowBytes))
        
        if (self.isMipmaped == true){
            self.generateMipMapLayersUsingSystemFunc(texture, device: device, commandQ: commandQ, block: { (buffer) -> Void in
                print("mips generated")
            })
        }
        
        print("mipCount:\(texture.mipmapLevelCount)")
    }
    
    
    
    class func textureCopy(source source: MTLTexture,device: MTLDevice, mipmaped: Bool) -> MTLTexture {
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.BGRA8Unorm, width: Int(source.width), height: Int(source.height), mipmapped: mipmaped)
        let copyTexture = device.newTextureWithDescriptor(texDescriptor)
        
        
        let region = MTLRegionMake2D(0, 0, Int(source.width), Int(source.height))
        let pixelsData = malloc(source.width * source.height * 4)
        source.getBytes(pixelsData, bytesPerRow: Int(source.width) * 4, fromRegion: region, mipmapLevel: 0)
        copyTexture.replaceRegion(region, mipmapLevel: 0, withBytes: pixelsData, bytesPerRow: Int(source.width) * 4)
        return copyTexture
    }
    
    class func copyMipLayer(source source: MTLTexture, destination:MTLTexture, mipLvl: Int){
        let q = Int(powf(2, Float(mipLvl)))
        let mipmapedWidth = max(Int(source.width)/q,1)
        let mipmapedHeight = max(Int(source.height)/q,1)
        
        let region = MTLRegionMake2D(0, 0, mipmapedWidth, mipmapedHeight)
        let pixelsData = malloc(mipmapedHeight * mipmapedWidth * 4)
        source.getBytes(pixelsData, bytesPerRow: mipmapedWidth * 4, fromRegion: region, mipmapLevel: mipLvl)
        destination.replaceRegion(region, mipmapLevel: mipLvl, withBytes: pixelsData, bytesPerRow: mipmapedWidth * 4)
        free(pixelsData)
    }
    
    //MARK: - Generating UIImage from texture mip layers
    func image(mipLevel mipLevel: Int) -> UIImage{
        
        let p = self.bytesForMipLevel(mipLevel: mipLevel)
        let q = Int(powf(2, Float(mipLevel)))
        let mipmapedWidth = max(self.width / q,1)
        let mipmapedHeight = max(self.height / q,1)
        let rowBytes = mipmapedWidth * 4
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGBitmapContextCreate(p, mipmapedWidth, mipmapedHeight, 8, rowBytes, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)
        let imgRef = CGBitmapContextCreateImage(context)
        let image = UIImage(CGImage: imgRef!)
        return image
    }
    
    func image() -> UIImage{
        return self.image(mipLevel: 0)
    }
    
    //MARK: - Getting raw bytes from texture mip layers
    func bytesForMipLevel(mipLevel mipLevel: Int) -> UnsafeMutablePointer<Void>{
        let q = Int(powf(2, Float(mipLevel)))
        let mipmapedWidth = max(Int(self.width) / q,1)
        let mipmapedHeight = max(Int(self.height) / q,1)
        
        let rowBytes = Int(mipmapedWidth * 4)
        
        let region = MTLRegionMake2D(0, 0, mipmapedWidth, mipmapedHeight)
        let pointer = malloc(rowBytes * mipmapedHeight)
        self.texture.getBytes(pointer, bytesPerRow: rowBytes, fromRegion: region, mipmapLevel: mipLevel)
        return pointer
    }
    
    func bytes() -> UnsafeMutablePointer<Void>{
        return self.bytesForMipLevel(mipLevel: 0)
    }
    
    func generateMipMapLayersUsingSystemFunc(texture: MTLTexture, device: MTLDevice, commandQ: MTLCommandQueue,block: MTLCommandBufferHandler){
        
        let commandBuffer = commandQ.commandBuffer()
        
        commandBuffer.addCompletedHandler(block)
        
        let blitCommandEncoder = commandBuffer.blitCommandEncoder()
        
        blitCommandEncoder.generateMipmapsForTexture(texture)
        blitCommandEncoder.endEncoding()
        
        commandBuffer.commit()
    }
    
}
