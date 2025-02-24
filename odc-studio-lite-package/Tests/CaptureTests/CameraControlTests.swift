//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import Capture
import Testing
import ConcurrencyExtras

@MainActor
@Suite
struct CameraControlTests {
    
    fileprivate let preferredCameraController = MockPreferredCameraController()
    fileprivate let videoDevicesProvider = MockVideoDevicesProvider()
    
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
            
            let cameraControl = CameraControl(
                preferredCameraController: preferredCameraController, 
                videoDevicesProvider: videoDevicesProvider)
            
            cameraControl.selectedCamera = camera
        }
    }
    
    @Test("""
    Given preferredCamera is selected, \
    When listenForCameras is called, \
    Then selectedCamera is set
    """)
    func preferredCameraIsInitiallySet() async throws {
        await withMainSerialExecutor {
            let camera = CaptureDevice(id: "ID", name: "Camera")
            preferredCameraController.stubPreferredCamera(camera)
            
            let cameraControl = CameraControl(
                preferredCameraController: preferredCameraController,
                videoDevicesProvider: videoDevicesProvider)
            
            async let _ = cameraControl.listenForCameras()
            
            await Task.megaYield()
            
            #expect(cameraControl.selectedCamera == camera)
        }
    }
    
    @Test("""
    When the list of available cameras is updated, \
    Then the list of cameras changes
    """)
    func listOfCamerasUpdates() async throws {
        await withMainSerialExecutor {
            let cameraControl = CameraControl(
                preferredCameraController: preferredCameraController,
                videoDevicesProvider: videoDevicesProvider)
            
            async let _ = cameraControl.listenForCameras()
            
            @MainActor
            func assertVideoDevices(_ devices: [CaptureDevice]) async {
                videoDevicesProvider.stubVideoDevices(devices)
                
                await Task.megaYield()
                
                #expect(cameraControl.listOfCameras == devices)
            }
            
            await assertVideoDevices([
                CaptureDevice(id: "ID1", name: "Camera1"),
            ])
            await assertVideoDevices([
                CaptureDevice(id: "ID1", name: "Camera1"),
                CaptureDevice(id: "ID2", name: "Camera2"),
            ])
        }
    }
}

private final class MockPreferredCameraController: PreferredCameraControlling {
    
    var preferredCamera: AsyncStream<CaptureDevice?> {
        let camera = preferredCameraValue
        return AsyncStream {
            camera
        }
    }
    
    var onPreferredCameraUpdated: ((CaptureDevice?) -> Void)?
    
    private var preferredCameraValue: CaptureDevice?
    
    init() {}
    
    func setPreferredCamera(_ preferredCamera: CaptureDevice?) {
        onPreferredCameraUpdated?(preferredCamera)
    }
    
    func stubPreferredCamera(_ preferredCamera: CaptureDevice?) {
        preferredCameraValue = preferredCamera
    }
}

private final class MockVideoDevicesProvider: VideoDevicesProviding {
    
    let videoDevices: AsyncStream<[CaptureDevice]>
    private let continuation: AsyncStream<[CaptureDevice]>.Continuation
    
    init() {
        (videoDevices, continuation) = AsyncStream.makeStream(of: [CaptureDevice].self)
    }

    deinit {
        continuation.finish()
    }

    func stubVideoDevices(_ videoDevices: [CaptureDevice]) {
        continuation.yield(videoDevices)
    }
}

extension Task where Success == Never, Failure == Never {
    
    fileprivate static func megaYield() async {
        for _ in 0..<50 {
            await Task.yield()
        }
    }
}
