//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import AudioVideoKit

@MainActor
@Observable
final class StreamConfiguration {

    var selectedCamera: CaptureDevice?
    var selectedMicrophone: CaptureDevice?
}
