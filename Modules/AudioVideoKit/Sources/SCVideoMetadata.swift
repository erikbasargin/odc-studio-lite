//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

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
    
    public init?(_ sampleBuffer: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>) {
        let sampleAttachments = sampleBuffer.sampleProperties.first?.attachments.dictionaryRepresentation
        let rawStatus = sampleAttachments?[SCStreamFrameInfo.status.rawValue] as? Int
        guard let rawStatus, let status = SCFrameStatus(rawValue: rawStatus) else {
            return nil
        }
        self.status = status
    }
}
