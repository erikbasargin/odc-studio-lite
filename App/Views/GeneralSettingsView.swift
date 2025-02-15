//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import SwiftUI

struct GeneralSettingsView: View {
    
    @Environment(BroadcastManager.self) private var broadcastManager
    
    var body: some View {
        @Bindable var broadcastManager = broadcastManager
        
        Form {
            Section("Twitch") {
                SecureField("Primary Stream key", text: $broadcastManager.primaryStreamKey)
            }
        }
    }
}


#Preview {
    GeneralSettingsView()
        .environment(BroadcastManager())
}
