//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AVFoundation
import AudioVideoKit
import Testing

@Suite
struct CMSampleBufferTests {
    
    @Test func sampleBufferWithoutIOSurface() throws {
        let imageBuffer = try makeCVImageBufferWithoutIOSurface()
        let sampleBuffer = try makeCMSampleBuffer(imageBuffer: imageBuffer)
        #expect(sampleBuffer.ioSurface == nil)
    }
    
    @Test func sampleBufferWithIOSurface() throws {
        let imageBuffer = try makeCVImageBufferWithIOSurface()
        let sampleBuffer = try makeCMSampleBuffer(imageBuffer: imageBuffer)
        #expect(sampleBuffer.ioSurface != nil)
    }
}

extension CMSampleBufferTests {
    
    fileprivate func makeCMSampleBuffer(imageBuffer: CVImageBuffer) throws -> CMSampleBuffer {
        try CMSampleBuffer(
            imageBuffer: imageBuffer,
            formatDescription: .init(imageBuffer: imageBuffer),
            sampleTiming: .init(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero)
        )
    }
    
    fileprivate func makeCVImageBufferWithoutIOSurface() throws -> CVImageBuffer {
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
    
    fileprivate func makeCVImageBufferWithIOSurface() throws -> CVImageBuffer {
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
                ] as CFDictionary))
        
        var imageBuffer: Unmanaged<CVImageBuffer>?
        CVPixelBufferCreateWithIOSurface(
            kCFAllocatorDefault,
            ioSurfaceRef,
            [:] as CFDictionary,
            &imageBuffer
        )
        
        return try #require(imageBuffer?.takeUnretainedValue())
    }
}
