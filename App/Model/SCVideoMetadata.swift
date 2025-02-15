//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit

struct SCVideoMetadata: Sendable {
    
    let status: SCFrameStatus
}

extension SCVideoMetadata {
    
    init?(_ attachments: CMSampleBuffer.SampleAttachmentsArray) {
        guard let rawStatus = attachments.first?[.status] as? Int, let status = SCFrameStatus(rawValue: rawStatus) else {
            return nil
        }
        self.status = status
    }
}
