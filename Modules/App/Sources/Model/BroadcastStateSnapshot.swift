//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation

import AudioVideoKit

struct BroadcastStateSnapshot: Equatable, Sendable {
    var bandwidthTestEnabled = false
    var primaryStreamKey = ""
    var isBroadcasting = false
    var cameraIsAuthorized = false
    var selectedCamera: CaptureDevice?
    var selectedMicrophone: CaptureDevice?
}
