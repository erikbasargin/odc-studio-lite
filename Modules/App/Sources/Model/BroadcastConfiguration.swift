//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import Foundation

struct BroadcastConfiguration: Equatable, Sendable {
    var bandwidthTestEnabled = false
    var primaryStreamKey = ""
    var isBroadcasting = false
    var cameraIsAuthorized = false
    var selectedCamera: CaptureDevice?
    var selectedMicrophone: CaptureDevice?
}
