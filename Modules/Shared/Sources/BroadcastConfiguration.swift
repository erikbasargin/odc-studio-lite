//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import Foundation

public struct BroadcastConfiguration: Equatable, Sendable {
    public var bandwidthTestEnabled = false
    public var primaryStreamKey = ""
    public var isBroadcasting = false
    public var cameraIsAuthorized = false
    public var selectedCamera: CaptureDevice?
    public var selectedMicrophone: CaptureDevice?
    
    public init(
        bandwidthTestEnabled: Bool = false,
        primaryStreamKey: String = "",
        isBroadcasting: Bool = false,
        cameraIsAuthorized: Bool = false,
        selectedCamera: CaptureDevice? = nil,
        selectedMicrophone: CaptureDevice? = nil
    ) {
        self.bandwidthTestEnabled = bandwidthTestEnabled
        self.primaryStreamKey = primaryStreamKey
        self.isBroadcasting = isBroadcasting
        self.cameraIsAuthorized = cameraIsAuthorized
        self.selectedCamera = selectedCamera
        self.selectedMicrophone = selectedMicrophone
    }
}
