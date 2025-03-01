//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Observation
import AudioVideoKit

@MainActor
@Observable
public final class AudioControl {
    
    public var selectedMicrophone: CaptureDevice?
    
    public private(set) var listOfMicrophones: [CaptureDevice] = []

    public init() {}

    public func listenForMicrophones() async {
        
    }
}
