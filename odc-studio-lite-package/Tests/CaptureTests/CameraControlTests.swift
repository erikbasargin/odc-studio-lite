//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import Capture
import Testing

@MainActor
@Suite
struct CameraControlTests {
    
    fileprivate let preferredCameraController = MockPreferredCameraController()
    
    @Test("""
    When selectedCamera is selected, \
    Then preferredCamera changes
    """)
    func preferredCameraChanges() async throws {
        let camera = CaptureDevice(id: "ID", name: "Camera")
        
        await confirmation { confirmation in
            preferredCameraController.onPreferredCameraUpdated = { preferredCamera in
                #expect(preferredCamera == camera)
                confirmation()
            }
            
            let cameraControl = CameraControl(preferredCameraController: preferredCameraController)
            
            cameraControl.selectedCamera = camera
        }
    }
    
    
}

private final class MockPreferredCameraController: PreferredCameraControlling {
    
    let preferredCamera: AsyncStream<CaptureDevice?>
    
    var onPreferredCameraUpdated: ((CaptureDevice?) -> Void)?
    
    init() {
        preferredCamera = AsyncStream { _ in }
    }
    
    func setPreferredCamera(_ preferredCamera: CaptureDevice?) {
        onPreferredCameraUpdated?(preferredCamera)
    }
}
