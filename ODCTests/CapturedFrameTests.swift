//
//  CapturedFrameTests.swift
//  ODCTests
//
//  Created by Erik Basargin on 06/10/2024.
//

import Testing

import ScreenCaptureKit

@testable import ODC

@Suite("CapturedFrame + CMSampleBuffer")
struct CapturedFrameAndCMSampleBufferTests {
    
    @Suite("Given CMSampleBuffer with IOSurface")
    struct GivenCMSampleBufferWithIOSurface {
        
        let surface: IOSurface
        
        @Test("CapturedFrame created when SCFrameStatus is .complete")
        func capturedFrameCreated() throws {
            let sampleBuffer = try makeSampleBuffer(frameStatus: .complete)
            
            let frame = try CapturedFrame(sampleBuffer)
            #expect(frame?.surface == surface)
        }
        
        @Test(
            "CapturedFrame is nil when SCFrameStatus is",
            arguments: [SCFrameStatus.idle, .blank, .suspended, .started, .stopped]
        )
        func givenSCStreamFrameInfoStatus(_ frameStatus: SCFrameStatus) async throws {
            let sampleBuffer = try makeSampleBuffer(frameStatus: frameStatus)
            
            #expect(try CapturedFrame(sampleBuffer) == nil)
        }
    }
    
    @Test("CapturedFrame throws sampleBufferInvalid when CMSampleBuffer is invalid")
    func capturedFrameThrowsSampleBufferInvalid() throws {
        let sampleBuffer = try CMSampleBuffer(dataBuffer: nil, formatDescription: nil, numSamples: 0, sampleTimings: [], sampleSizes: [])
        try sampleBuffer.invalidate()
        
        #expect(throws: CaptureFrameError.invalidSMSampleBuffer) {
            try CapturedFrame(sampleBuffer)
        }
    }
    
    @Test("CapturedFrame throws noStreamFrameInfo when CMSampleBuffer without stream frame info status")
    func capturedFrameThrowsNoStreamFrameInfo_givenCMSampleBufferWithoutStreamFrameSampleAttachment() throws {
        let sampleBuffer = try makeSampleBufferWithNoSampleAttachments()
        
        #expect(throws: CaptureFrameError.noStreamFrameInfo) {
            try CapturedFrame(sampleBuffer)
        }
    }
    
    @Test("CapturedFrame throws noImageBuffer when CMSampleBuffer without ImageBuffer when SCFrameStatus is .complete")
    func capturedFrameThrowsNoImageBuffer_givenSampleBufferWithNoImageBufferAndSCStreamFrameInfoStatusIsComplete() throws {
        let sampleBuffer = try makeCMSampleBufferWithNoImageBuffer(frameStatus: .complete)
        
        #expect(throws: CaptureFrameError.noImageBuffer) {
            try CapturedFrame(sampleBuffer)
        }
    }
    
    @Test("CapturedFrame throws noIOSurface when CMSampleBuffer without IOSurface when SCFrameStatus is .complete")
    func capturedFrameThrowsNoIOSurface() throws {
        let sampleBuffer = try makeCMSampleBufferWithoutIOSurface(frameStatus: .complete)
        
        #expect(throws: CaptureFrameError.noIOSurface) {
            try CapturedFrame(sampleBuffer)
        }
    }
}

// MARK: - Extensions

private extension CapturedFrameAndCMSampleBufferTests.GivenCMSampleBufferWithIOSurface {
    
    init() {
        let textureImageWidth = 1024
        let textureImageHeight = 1024
        
        surface = try! #require(IOSurfaceCreate([
            kIOSurfaceWidth: textureImageWidth,
            kIOSurfaceHeight: textureImageHeight,
            kIOSurfaceBytesPerElement: 4,
            kIOSurfaceBytesPerRow: textureImageWidth * 4,
            kIOSurfaceAllocSize: textureImageWidth * textureImageHeight * 4,
            kIOSurfacePixelFormat: kCVPixelFormatType_32BGRA
        ] as CFDictionary)) as IOSurface
    }
    
    func makeSampleBuffer(frameStatus: SCFrameStatus) throws -> CMSampleBuffer {
        let sampleBuffer = try makeCMSampleBuffer(surface: surface)
        
        sampleBuffer.sampleAttachments[0][.streamFrameInfoStatus] = frameStatus.rawValue
        
        return sampleBuffer
    }
    
    private func makeCMSampleBuffer(surface: IOSurface) throws -> CMSampleBuffer {
        func makeImageBuffer() throws -> CVImageBuffer {
            var imageBuffer: Unmanaged<CVImageBuffer>?
            let status = CVPixelBufferCreateWithIOSurface(
                kCFAllocatorDefault,
                surface as IOSurfaceRef,
                [:] as CFDictionary,
                &imageBuffer)
            
            guard status == 0, let imageBuffer else {
                throw PixelBufferError.pixelBufferIsNotCreated
            }
            
            return imageBuffer.takeRetainedValue()
        }
        
        let imageBuffer = try makeImageBuffer()
        return try CMSampleBuffer(
            imageBuffer: imageBuffer,
            formatDescription: .init(imageBuffer: imageBuffer),
            sampleTiming: .init(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero))
    }
}

private extension CapturedFrameAndCMSampleBufferTests {

    func makeSampleBufferWithNoSampleAttachments() throws -> CMSampleBuffer {
        try CMSampleBuffer(dataBuffer: nil, formatDescription: nil, numSamples: 0, sampleTimings: [], sampleSizes: [])
    }
    
    func makeCMSampleBufferWithoutIOSurface(frameStatus: SCFrameStatus) throws -> CMSampleBuffer {
        var imageBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, 100, 100, kCVPixelFormatType_32BGRA, nil, &imageBuffer)
        guard status == 0, let imageBuffer else {
            throw PixelBufferError.pixelBufferIsNotCreated
        }
        let sampleBuffer = try CMSampleBuffer(
            imageBuffer: imageBuffer,
            formatDescription: .init(imageBuffer: imageBuffer),
            sampleTiming: .init(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero))
        
        sampleBuffer.sampleAttachments[0][.streamFrameInfoStatus] = frameStatus.rawValue
        
        return sampleBuffer
    }
    
    func makeCMSampleBufferWithNoImageBuffer(frameStatus: SCFrameStatus) throws -> CMSampleBuffer {
        let sampleBuffer = try CMSampleBuffer(
            dataBuffer: nil,
            formatDescription: nil,
            numSamples: 1,
            sampleTimings: [],
            sampleSizes: [])
        
        sampleBuffer.sampleAttachments[0][.streamFrameInfoStatus] = frameStatus.rawValue
        
        return sampleBuffer
    }
}

private enum PixelBufferError: Error {
    case pixelBufferIsNotCreated
}
