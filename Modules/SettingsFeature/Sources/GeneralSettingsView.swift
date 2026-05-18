//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import SwiftUI

public struct GeneralSettingsView: View {
    
    @Bindable public var store: StoreOf<SettingsFeature>
    
    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }
    
    public var body: some View {
        Form {
            Section("Twitch") {
                SecureField(
                    "Primary Stream key",
                    text: $store.primaryStreamKey.sending(\.primaryStreamKeyChanged)
                )
            }
        }
    }
}

#Preview {
    GeneralSettingsView(
        store: Store(initialState: SettingsFeature.State()) {}
    )
}
