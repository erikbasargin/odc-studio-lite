//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AVFoundation
import AudioVideoKit
import Foundation

@MainActor
@Observable
public final class CameraControl {
    
    public var selectedCamera: CaptureDevice? {
        didSet {
            preferredCameraController.setPreferredCamera(selectedCamera)
        }
    }
    
    private(set) var listOfCameras: [CaptureDevice] = []
    
    @ObservationIgnored
    private let preferredCameraController: any PreferredCameraControlling
    
    package init(
        preferredCameraController: any PreferredCameraControlling
    ) {
        self.preferredCameraController = preferredCameraController
    }
    
    func listenForCameras() async {
        
    }
}

package protocol PreferredCameraControlling {
    
    var preferredCamera: AsyncStream<CaptureDevice?> { get }
    
    func setPreferredCamera(_ preferredCamera: CaptureDevice?)
}
