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
        let imageBuffer = try CaptureStreamHelper.makeCVImageBufferWithoutIOSurface()
        let sampleBuffer = try CaptureStreamHelper.makeCMSampleBuffer(imageBuffer: imageBuffer)
        #expect(sampleBuffer.ioSurface == nil)
    }
    
    @Test func sampleBufferWithIOSurface() throws {
        let imageBuffer = try CaptureStreamHelper.makeCVImageBufferWithIOSurface()
        let sampleBuffer = try CaptureStreamHelper.makeCMSampleBuffer(imageBuffer: imageBuffer)
        #expect(sampleBuffer.ioSurface != nil)
    }
}
