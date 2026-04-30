//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import BroadcastFeature
import ComposableArchitecture
import SwiftUI

struct MenuBarExtraContentView: View {
    
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        let captureStore = store.scope(state: \.capture, action: \.capture)
        @Bindable var broadcastStore = store.scope(state: \.broadcast, action: \.broadcast)
        
        CameraControlSection(store: captureStore)
        AudioControlSection(store: captureStore)
        
        TwitchBroadcastSection(store: broadcastStore) {
            store.send(broadcastStore.isBroadcasting ? .stopBroadcast : .startBroadcast)
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
