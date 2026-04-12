//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import SwiftUI

struct MenuBarExtraContentView: View {
    
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        @Bindable var broadcastStore = store.scope(state: \.broadcast, action: \.broadcast)

        CameraControlSection(store: broadcastStore)
            .disabled(!broadcastStore.cameraIsAuthorized)
            
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
        
        AudioControlSection(store: broadcastStore)
        
//        Section("Audio") {
//            Toggle("Capture microphone", isOn: $broadcastManager.captureMicrophone)
//        }
        
        Section("Twitch Broadcast") {
            Toggle(
                "Bandwidth test",
                isOn: $broadcastStore.bandwidthTestEnabled.sending(\.bandwidthTestEnabledChanged)
            )
            .disabled(broadcastStore.isBroadcasting)
            
            Button("\(broadcastStore.isBroadcasting ? "Stop" : "Start") broadcast") {
                broadcastStore.send(.startStopBroadcastButtonTapped)
            }
            .disabled(store.settings.primaryStreamKey.isEmpty)
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
        store: Store(initialState: AppFeature.State()) {}
    )
}
