//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import ComposableArchitecture
import Shared
import SwiftUI

struct CameraControlSection: View {
    
    @Bindable var store: StoreOf<CaptureFeature>
    
    var body: some View {
        Section("Video") {
            Picker(
                "Camera - \(store.selectedCamera?.name ?? "not selected")",
                selection: $store.selectedCamera.sending(\.selectedCameraChanged)
            ) {
                ForEach(store.availableCameras) { device in
                    Text(verbatim: device.name)
                        .tag(device)
                }
            }
            
            Button(store.isCaptureSessionRunning ? "Stop capture session" : "Start capture session") {
                store.send(store.isCaptureSessionRunning ? .stopCaptureSession : .startCaptureSession)
            }
            .disabled(!store.cameraIsAuthorized || store.selectedCamera == nil)
        }
        .task {
            let discoveryService = CaptureDevice.DiscoveryService(
                mediaType: .video,
                deviceTypes: [.builtInWideAngleCamera, .continuityCamera]
            )
            for await cameras in discoveryService.devices {
                store.send(.availableCamerasChanged(cameras))
            }
        }
    }
}

#Preview {
    CameraControlSection(
        store: Store(
            initialState: CaptureFeature.State(
                configuration: BroadcastConfiguration()
            )
        ) {
            CaptureFeature()
        }
    )
}
