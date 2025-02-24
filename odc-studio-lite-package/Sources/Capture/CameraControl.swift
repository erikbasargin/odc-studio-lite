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
    private let captureDeviceDiscoveryService: any CaptureDeviceDiscoveryService
    
    package init(
        preferredCameraController: any PreferredCameraControlling,
        captureDeviceDiscoveryService: any CaptureDeviceDiscoveryService
    ) {
        self.preferredCameraController = preferredCameraController
        self.captureDeviceDiscoveryService = captureDeviceDiscoveryService
    }
    
    public func listenForCameras() async {
        for await preferredCamera in preferredCameraController.preferredCamera.prefix(1) {
            selectedCamera = preferredCamera
        }
        
        for await devices in captureDeviceDiscoveryService.devices {
            listOfCameras = devices
        }
    }
}
