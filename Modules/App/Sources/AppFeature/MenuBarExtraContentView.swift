//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import SwiftUI

struct MenuBarExtraContentView: View {

    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        let captureStore = store.scope(state: \.capture, action: \.capture)
        @Bindable var broadcastStore = store.scope(state: \.broadcast, action: \.broadcast)

        CameraControlSection(store: captureStore)
        AudioControlSection(store: captureStore)

        Section("Twitch Broadcast") {
            Toggle(
                "Bandwidth test",
                isOn: $broadcastStore.bandwidthTestEnabled.sending(\.bandwidthTestEnabledChanged)
            )
            .disabled(broadcastStore.isBroadcasting)
            
            Button("\(broadcastStore.isBroadcasting ? "Stop" : "Start") broadcast") {
                store.send(broadcastStore.isBroadcasting ? .stopBroadcast : .startBroadcast)
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
