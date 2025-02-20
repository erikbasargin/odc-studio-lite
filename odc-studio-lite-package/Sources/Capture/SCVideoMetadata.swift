//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import ScreenCaptureKit

public struct SCVideoMetadata: Sendable {
    public let status: SCFrameStatus
}

extension SCVideoMetadata {
    
    public init?(_ sampleBuffer: CMSampleBuffer) {
        guard let rawStatus = sampleBuffer.sampleAttachments.first?[.status] as? Int,
            let status = SCFrameStatus(rawValue: rawStatus)
        else {
            return nil
        }
        self.status = status
    }
}
