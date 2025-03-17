//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit
import Testing
import ConcurrencyExtras

@testable import AudioVideoKit

@Suite(.timeLimit(.minutes(1)))
struct CaptureStreamTests {
    
    @Test
    func producesWhenNewOutputFrameIsReceived() async throws {
        let source = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let sampleBuffer = try makeCMSampleBuffer()
        let captureStream = CaptureStream(source: source, type: .screen)
        
        async let capturedPayloads = captureStream.prefix(1).reduce(into: []) { partialResult, payload in
            partialResult.append(payload)
        }
        
        await Task.megaYield()
        
        source.stubOutputSampleBuffer(sampleBuffer, type: .screen)
        
        try await #expect(
            capturedPayloads == [
                CapturedPayload(sampleBuffer: sampleBuffer)
            ]
        )
    }
    
    @Test
    func producesPayloadOfProvidedType() async throws {
        let source = MockSCStream(filter: .init(), configuration: .init(), delegate: nil)
        let videoSampleBuffer = try makeCMSampleBuffer()
        let audioSampleBuffer = try CaptureStreamHelper.makeAudioSampleBuffer()
        let captureStream = CaptureStream(source: source, type: .screen)
        
        async let capturedPayloads = captureStream.prefix(1).reduce(into: []) { partialResult, payload in
            partialResult.append(payload)
        }
        
        await Task.megaYield()
        
        source.stubOutputSampleBuffer(audioSampleBuffer, type: .audio)
        
        await Task.megaYield()
        
        source.stubOutputSampleBuffer(videoSampleBuffer, type: .screen)
        
        try await #expect(
            capturedPayloads == [
                CapturedPayload(sampleBuffer: videoSampleBuffer)
            ]
        )
    }
}

extension CaptureStreamTests {
    
    fileprivate func makeCMSampleBuffer() throws -> CMSampleBuffer {
        try CaptureStreamHelper.makeCMSampleBuffer(
            imageBuffer: try CaptureStreamHelper.makeCVImageBufferWithIOSurface()
        )
    }
}

private final class MockSCStream: SCStream {
    
    private var currentStreamOutput: (any SCStreamOutput)?
    
    override func addStreamOutput(
        _ output: any SCStreamOutput,
        type: SCStreamOutputType,
        sampleHandlerQueue: dispatch_queue_t?
    ) throws {
        currentStreamOutput = output
    }

    func stubOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer, type: SCStreamOutputType) {
        currentStreamOutput?.stream?(self, didOutputSampleBuffer: sampleBuffer, of: type)
    }
}
