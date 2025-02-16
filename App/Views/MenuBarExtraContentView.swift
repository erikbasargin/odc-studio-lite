//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import SwiftUI

struct MenuBarExtraContentView: View {
    
    @Environment(BroadcastManager.self) private var broadcastManager
    
    var body: some View {
        @Bindable var broadcastManager = broadcastManager
        
        Section("Video") {
            Toggle("Exclude app from stream", isOn: $broadcastManager.excludeAppFromStream)
            Picker(
                "Camera - \(broadcastManager.selectedCameraDevice?.name ?? "not selected")",
                selection: $broadcastManager.selectedCameraDevice
            ) {
                ForEach(broadcastManager.videoDevices) { device in
                    Text(verbatim: device.name)
                        .tag(device)
                }
            }
            .disabled(!broadcastManager.cameraIsAuthorized)
        }
        .task {
            await broadcastManager.listenForVideoDevices()
        }
        
        Section("Audio") {
            Toggle("Capture microphone", isOn: $broadcastManager.captureMicrophone)
        }
        
        Section("Twitch Broadcast") {
            Toggle("Bandwidth test", isOn: $broadcastManager.bandwidthTestEnabled)
                .disabled(broadcastManager.isBroadcasting)
            
            Button("\(broadcastManager.isBroadcasting ? "Stop" : "Start") broadcast") {
                Task {
                    await broadcastManager.toogleBroadcast()
                }
            }
            .disabled(broadcastManager.primaryStreamKey.isEmpty)
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
    MenuBarExtraContentView()
        .environment(BroadcastManager())
}
