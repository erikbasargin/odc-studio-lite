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
        try CaptureStreamHelper.makeCMSampleBuffer(
            imageBuffer: try CaptureStreamHelper.makeCVImageBufferWithIOSurface()
        )
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
