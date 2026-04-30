//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import SwiftUI

public struct TwitchBroadcastSection: View {
    
    @Bindable public var store: StoreOf<BroadcastFeature>
    
    public init(store: StoreOf<BroadcastFeature>) {
        self.store = store
    }
    
    public var body: some View {
        Section("Twitch Broadcast") {
            Toggle(
                "Bandwidth test",
                isOn: $store.bandwidthTestEnabled.sending(\.bandwidthTestEnabledChanged)
            )
            .disabled(store.isBroadcasting)
            
            Button("\(store.isBroadcasting ? "Stop" : "Start") broadcast") {
                store.send(store.isBroadcasting ? .stopBroadcast : .startBroadcast)
            }
        }
    }
}

#Preview {
    List {
        TwitchBroadcastSection(
            store: Store(initialState: BroadcastFeature.State()) {
                BroadcastFeature()
            })
    }
}
