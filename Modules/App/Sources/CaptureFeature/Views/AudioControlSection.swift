//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import ComposableArchitecture
import SwiftUI

struct AudioControlSection: View {

    @Bindable var store: StoreOf<CaptureFeature>

    var body: some View {
        Section("Audio") {
            Picker(
                "Microphone - \(store.selectedMicrophone?.name ?? "not selected")",
                selection: $store.selectedMicrophone.sending(\.selectedMicrophoneChanged)
            ) {
                ForEach(store.availableMicrophones) { device in
                    Text(verbatim: device.name)
                        .tag(device)
                }
            }
        }
        .task {
            let discoveryService = CaptureDevice.DiscoveryService(
                mediaType: .audio,
                deviceTypes: [.microphone]
            )
            for await microphones in discoveryService.devices {
                store.send(.availableMicrophonesChanged(microphones))
            }
        }
    }
}

#Preview {
    AudioControlSection(
        store: Store(
            initialState: CaptureFeature.State(
                configuration: BroadcastConfiguration()
            )
        ) {
            CaptureFeature()
        }
    )
}
