//
//  Image+CVPixelBuffer.swift
//  FaceEmotionClassifier
//
//  Created by Sharan Thakur on 16/03/24.
//

#if canImport(UIKit)
import UIKit

typealias ImageProvider = UIImage

extension UIImage {
    func colorPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }

        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

            context?.translateBy(x: 0, y: self.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)

            UIGraphicsPushContext(context!)
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

            return pixelBuffer
        }

        return nil
    }
}
#elseif canImport(AppKit)
import AppKit

typealias ImageProvider = NSImage

extension NSImage {
    // function used by all functions below. It shouldn't be used directly
    func __toPixelBuffer(PixelFormatType: OSType) -> CVPixelBuffer? {
        var bitsPerC   = 8
        var colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue
        
        // if we need depth/disparity
        if PixelFormatType == kCVPixelFormatType_DepthFloat32 || PixelFormatType == kCVPixelFormatType_DisparityFloat32 {
            bitsPerC   = 32
            colorSpace = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGImageAlphaInfo.none.rawValue | CGBitmapInfo.floatComponents.rawValue
        }
        // if we need mask
        else if PixelFormatType == kCVPixelFormatType_OneComponent8 {
            bitsPerC   = 8
            colorSpace = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGImageAlphaInfo.alphaOnly.rawValue
        }
        
        let width  = Int(self.size.width)
        let height = Int(self.size.height)
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, PixelFormatType, attrs, &pixelBuffer)
        guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(resultPixelBuffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerC,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo)
        else {
            return nil
        }
        
        // context.translateBy(x: 0, y: height)
        // context.scaleBy(x: 1.0, y: -1.0)
        
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()
        
        CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return resultPixelBuffer
    }

    // return the NSImage as a color 32bit Color CVPixelBuffer
    func colorPixelBuffer() -> CVPixelBuffer? {
        return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_32ARGB)
    }

    func maskPixelBuffer() -> CVPixelBuffer? {
        return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_OneComponent8)
    }

    // return NSImage as a 32bit depthData CVPixelBuffer
    func depthPixelBuffer() -> CVPixelBuffer? {
        return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_DepthFloat32)
    }

    // return NSImage as a 32bit disparityData CVPixelBuffer
    func disparityPixelBuffer() -> CVPixelBuffer? {
        return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_DisparityFloat32)
    }
}
#endif
