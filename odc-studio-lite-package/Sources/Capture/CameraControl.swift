//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AVFoundation
import AudioVideoKit

@MainActor
@Observable
public final class CameraControl {
    
    public var selectedCamera: CaptureDevice? {
        didSet {
            preferredCameraController.setPreferredCamera(selectedCamera)
        }
    }
    
    public private(set) var listOfCameras: [CaptureDevice] = []
    
    @ObservationIgnored
    private let preferredCameraController: any PreferredCameraControlling
    
    @ObservationIgnored
    private let videoDevicesProvider: any VideoDevicesProviding
    
    package init(
        preferredCameraController: any PreferredCameraControlling,
        videoDevicesProvider: any VideoDevicesProviding
    ) {
        self.preferredCameraController = preferredCameraController
        self.videoDevicesProvider = videoDevicesProvider
    }
    
    public func listenForCameras() async {
        for await preferredCamera in preferredCameraController.preferredCamera.prefix(1) {
            selectedCamera = preferredCamera
        }
        
        for await devices in videoDevicesProvider.videoDevices {
            listOfCameras = devices
        }
    }
}

package protocol PreferredCameraControlling {
    
    var preferredCamera: AsyncStream<CaptureDevice?> { get }
    
    func setPreferredCamera(_ preferredCamera: CaptureDevice?)
}

package protocol VideoDevicesProviding {
    var videoDevices: AsyncStream<[CaptureDevice]> { get }
}
