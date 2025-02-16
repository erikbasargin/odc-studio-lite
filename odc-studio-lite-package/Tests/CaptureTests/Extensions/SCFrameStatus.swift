//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit
import Testing

// swift-format-ignore: AvoidRetroactiveConformances
extension SCFrameStatus: @retroactive CustomTestStringConvertible {
    
    public var testDescription: String {
        switch self {
        case .complete:
            return "Complete"
        case .idle:
            return "Idle"
        case .blank:
            return "Blank"
        case .suspended:
            return "Suspended"
        case .started:
            return "Started"
        case .stopped:
            return "Stopped"
        @unknown default:
            return "Unknown"
        }
    }
}
