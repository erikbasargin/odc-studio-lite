//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import SwiftUI

import AudioVideoKit

struct MenuBarExtraContentView: View {
    
    @Bindable var store: StoreOf<BroadcastFeature>
    
    var body: some View {
        CameraControlSection(store: store)
            .disabled(!store.cameraIsAuthorized)
            
//        Section("Video") {
//            Toggle("Exclude app from stream", isOn: $broadcastManager.excludeAppFromStream)
//            Picker(
//                "Camera - \(broadcastManager.selectedCameraDevice?.name ?? "not selected")",
//                selection: $broadcastManager.selectedCameraDevice
//            ) {
//                ForEach(broadcastManager.videoDevices) { device in
//                    Text(verbatim: device.name)
//                        .tag(device)
//                }
//            }
//            .disabled(!broadcastManager.cameraIsAuthorized)
//        }
//        .task {
//            await broadcastManager.listenForVideoDevices()
//        }
        
        AudioControlSection(store: store)
        
//        Section("Audio") {
//            Toggle("Capture microphone", isOn: $broadcastManager.captureMicrophone)
//        }
        
        Section("Twitch Broadcast") {
            Toggle(
                "Bandwidth test",
                isOn: $store.bandwidthTestEnabled.sending(\.bandwidthTestEnabledChanged),
            )
                .disabled(store.isBroadcasting)
            
            Button("\(store.isBroadcasting ? "Stop" : "Start") broadcast") {
                store.send(.startStopBroadcastButtonTapped)
            }
            .disabled(store.primaryStreamKey.isEmpty)
        }
        
        Section {
            SettingsLink()
        }
        
        Button("Quit") {
            NSApplication.shared.terminate(self)
        }
    }
}

#Preview {
    MenuBarExtraContentView(
        store: Store(initialState: BroadcastFeature.State()) {}
    )
}
