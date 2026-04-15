//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import ComposableArchitecture
import SwiftUI

struct CameraControlSection: View {

    @Bindable var store: StoreOf<BroadcastFeature>
    
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
            initialState: BroadcastFeature.State(
                configuration: BroadcastConfiguration()
            )
        ) {
            BroadcastFeature()
        }
    )
}
