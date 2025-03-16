//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AVFoundation
import Testing

struct CaptureStreamHelper {
    
    static func makeCMSampleBuffer(imageBuffer: CVImageBuffer) throws -> CMSampleBuffer {
        try CMSampleBuffer(
            imageBuffer: imageBuffer,
            formatDescription: .init(imageBuffer: imageBuffer),
            sampleTiming: .init(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero)
        )
    }
    
    static func makeCVImageBufferWithIOSurface() throws -> CVImageBuffer {
        let imageWidth = 10
        let ioSurfaceRef = try #require(
            IOSurfaceCreate(
                [
                    kIOSurfaceWidth: imageWidth,
                    kIOSurfaceHeight: imageWidth,
                    kIOSurfaceBytesPerElement: 4,
                    kIOSurfaceBytesPerRow: imageWidth * 4,
                    kIOSurfaceAllocSize: imageWidth * imageWidth * 4,
                    kIOSurfacePixelFormat: kCVPixelFormatType_32BGRA,
                ] as CFDictionary
            )
        )
        
        var imageBuffer: Unmanaged<CVImageBuffer>?
        CVPixelBufferCreateWithIOSurface(
            kCFAllocatorDefault,
            ioSurfaceRef,
            [:] as CFDictionary,
            &imageBuffer
        )
        
        return try #require(imageBuffer?.takeUnretainedValue())
    }
    
    static func makeCVImageBufferWithoutIOSurface() throws -> CVImageBuffer {
        var imageBuffer: CVImageBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            100,
            100,
            kCVPixelFormatType_32BGRA,
            nil,
            &imageBuffer
        )
        return try #require(imageBuffer)
    }
}
