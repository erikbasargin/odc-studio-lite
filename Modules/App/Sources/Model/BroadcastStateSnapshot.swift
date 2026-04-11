//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation

struct BroadcastStateSnapshot: Equatable, Sendable {
    var bandwidthTestEnabled = false
    var primaryStreamKey = ""
    var isBroadcasting = false
}
