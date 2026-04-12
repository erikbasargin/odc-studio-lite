//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import SwiftUI

struct GeneralSettingsView: View {
    
    @Bindable var store: StoreOf<BroadcastFeature>
    
    var body: some View {
        Form {
            Section("Twitch") {
                SecureField(
                    "Primary Stream key",
                    text: $store.primaryStreamKey.sending(\.primaryStreamKeyChanged),
                )
            }
        }
    }
}

#Preview {
    GeneralSettingsView(
        store: Store(initialState: BroadcastFeature.State()) {}
    )
}
