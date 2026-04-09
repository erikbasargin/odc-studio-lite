//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import AudioVideoKit

@Observable
final class StreamConfiguration {

    public var selectedCamera: CaptureDevice?
    public var selectedMicrophone: CaptureDevice?
    
    public init() {}
}
