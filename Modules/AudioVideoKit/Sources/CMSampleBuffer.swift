//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit

extension CMSampleBuffer {
    
    package var ioSurface: IOSurface? {
        CVPixelBufferGetIOSurface(imageBuffer)?.takeUnretainedValue()
    }
}

extension CMSampleBuffer.PerSampleAttachmentsDictionary.Key {
    package static let status: Self = Self(rawValue: SCStreamFrameInfo.status.rawValue as CFString)
}
