//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit
import Testing
import ConcurrencyExtras

@testable import AudioVideoKit

@Suite
struct CaptureStreamTests {
    
    @Test
    func producesWhenNewOutputFrameIsReceived() async throws {
        let source = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let sampleBuffer = try makeCMSampleBuffer()
        let captureStream = CaptureStream(source: source, type: .screen)
        
        async let capturedPayloads = captureStream.prefix(1).reduce(into: []) { partialResult, payload in
            partialResult.append(payload)
        }
        
        await Task.megaYield(count: 20)
        
        source.stubOutputSampleBuffer(sampleBuffer, type: .screen)
        
        try await #expect(
            capturedPayloads == [
                CapturedPayload(sampleBuffer: sampleBuffer)
            ]
        )
    }
}

extension CaptureStreamTests {
    
    fileprivate func makeCMSampleBuffer() throws -> CMSampleBuffer {
        try makeCMSampleBuffer(imageBuffer: try makeCVImageBufferWithIOSurface())
    }
    
    fileprivate func makeCMSampleBuffer(imageBuffer: CVImageBuffer) throws -> CMSampleBuffer {
        try CMSampleBuffer(
            imageBuffer: imageBuffer,
            formatDescription: .init(imageBuffer: imageBuffer),
            sampleTiming: .init(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero)
        )
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

private final class MockSCStream: SCStream {
    
    private var streamOutputs: [SCStreamOutputType: any SCStreamOutput] = [:]
    
    override func addStreamOutput(
        _ output: any SCStreamOutput,
        type: SCStreamOutputType,
        sampleHandlerQueue: dispatch_queue_t?
    ) throws {
        streamOutputs[type] = output
    }

    func stubOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer, type: SCStreamOutputType) {
        streamOutputs[type]?.stream?(self, didOutputSampleBuffer: sampleBuffer, of: type)
    }
}
