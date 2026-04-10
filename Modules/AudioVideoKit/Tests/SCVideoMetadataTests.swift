//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit
import Testing

import AudioVideoKit

@Suite
struct SCVideoMetadataTests {
    
    @Test(
        "SCVideoMetadata contains frame status, given CMSampleBuffer",
        arguments: [
            SCFrameStatus.complete,
            .idle,
            .blank,
            .suspended,
            .started,
            .stopped,
        ]
    )
    func sampleBufferContains(status: SCFrameStatus) throws {
        let sampleBuffer = try makeCMSampleBufferWithFrameStatus(status)
        #expect(SCVideoMetadata(sampleBuffer)?.status == status)
    }
    
    @Test(
        "SCVideoMetadata contains frame status, given CMReadySampleBuffer",
        arguments: [
            SCFrameStatus.complete,
            .idle,
            .blank,
            .suspended,
            .started,
            .stopped,
        ]
    )
    func readySampleBufferContains(status: SCFrameStatus) throws {
        let sampleBuffer = try makeCMSampleBufferWithFrameStatus(status)
        let readyBuffer = CMReadySampleBuffer(unsafeBuffer: consume sampleBuffer)
        #expect(SCVideoMetadata(readyBuffer)?.status == status)
    }
    
    @Test("SCVideoMetadata is nil when there is no frame status, given empty CMSampleBuffer")
    func videoMetadataIsNilGivenEmptyCMSampleBuffer() throws {
        let sampleBuffer = try makeEmptyCMSampleBuffer()
        #expect(SCVideoMetadata(sampleBuffer) == nil)
    }
    
    @Test("SCVideoMetadata is nil when there is no frame status, given empty CMReadySampleBuffer")
    func videoMetadataIsNilGivenEmptCMReadySampleBuffer() throws {
        let sampleBuffer = try makeEmptyCMSampleBuffer()
        let readyBuffer = CMReadySampleBuffer(unsafeBuffer: consume sampleBuffer)
        #expect(SCVideoMetadata(readyBuffer) == nil)
    }
}

extension SCVideoMetadataTests {
    
    fileprivate func makeEmptyCMSampleBuffer() throws -> CMSampleBuffer {
        try CMSampleBuffer(
            dataBuffer: nil,
            formatDescription: nil,
            numSamples: 0,
            sampleTimings: [],
            sampleSizes: [])
    }
    
    fileprivate func makeCMSampleBufferWithFrameStatus(_ frameStatus: SCFrameStatus) throws -> CMSampleBuffer {
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
