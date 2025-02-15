//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit

extension CMSampleBuffer {
    
    var ioSurface: IOSurface? {
        CVPixelBufferGetIOSurface(imageBuffer)?.takeUnretainedValue()
    }
    
    var videoMetadata: SCVideoMetadata? {
        SCVideoMetadata(sampleAttachments)
    }
}

extension CMSampleBuffer.PerSampleAttachmentsDictionary.Key {
    
    static let status: Self = Self(rawValue: SCStreamFrameInfo.status.rawValue as CFString)
}
