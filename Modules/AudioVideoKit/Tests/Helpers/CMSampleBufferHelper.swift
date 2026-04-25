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
    
    static func makeAudioSampleBuffer() throws -> CMSampleBuffer {
        var sampleBuffer: CMSampleBuffer?
        let formatDescription = try CMFormatDescription(
            audioStreamBasicDescription: .init(
                mSampleRate: 48000,
                mFormatID: 1_819_304_813,
                mFormatFlags: 41,
                mBytesPerPacket: 4,
                mFramesPerPacket: 1,
                mBytesPerFrame: 4,
                mChannelsPerFrame: 2,
                mBitsPerChannel: 32,
                mReserved: 0
            )
        )
        
        CMAudioSampleBufferCreateWithPacketDescriptionsAndMakeDataReadyHandler(
            kCFAllocatorDefault,
            nil,
            false,
            formatDescription,
            1,
            .zero,
            nil,
            &sampleBuffer,
            nil
        )
        return try #require(sampleBuffer)
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
