//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Testing
import ScreenCaptureKit

import Capture

@Suite
struct SCVideoMetadataTests {
    
    @Test(
        "SCVideoMetadata contains frame status",
        arguments: [
            SCFrameStatus.complete,
            .idle,
            .blank,
            .suspended,
            .started,
            .stopped,
        ])
    func contains(status: SCFrameStatus) throws {
        let sampleBuffer = try makeCMSampleBufferWithFrameStatus(status)
        #expect(SCVideoMetadata(sampleBuffer)?.status == status)
    }
    
    @Test("SCVideoMetadata is nil when there is no frame status")
    func videoMetadataIsNil() throws {
        let sampleBuffer = try makeEmptyCMSampleBuffer()
        #expect(SCVideoMetadata(sampleBuffer) == nil)
    }
}

private extension SCVideoMetadataTests {
    
    func makeEmptyCMSampleBuffer() throws -> CMSampleBuffer {
        try CMSampleBuffer(
            dataBuffer: nil,
            formatDescription: nil,
            numSamples: 0,
            sampleTimings: [],
            sampleSizes: [])
    }
    
    func makeCMSampleBufferWithFrameStatus(_ frameStatus: SCFrameStatus) throws -> CMSampleBuffer {
        let sampleBuffer = try CMSampleBuffer(
            dataBuffer: nil,
            formatDescription: nil,
            numSamples: 1,
            sampleTimings: [],
            sampleSizes: [])
        
        sampleBuffer.sampleAttachments[0][.status] = frameStatus.rawValue
        
        return sampleBuffer
    }
}
