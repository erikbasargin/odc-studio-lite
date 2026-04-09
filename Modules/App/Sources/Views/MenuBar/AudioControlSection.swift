//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import SwiftUI
import AudioVideoKit

public struct AudioControlSection: View {
    
    @Environment(StreamConfiguration.self) private var streamConfiguration
    @State private var microphones: [CaptureDevice] = []
    
    public init() {}
    
    public var body: some View {
        @Bindable var streamConfiguration = self.streamConfiguration
        
        Section("Audio") {
            Picker(
                "Microphone - \(streamConfiguration.selectedMicrophone?.name ?? "not selected")",
                selection: $streamConfiguration.selectedMicrophone
            ) {
                ForEach(microphones) { device in
                    Text(verbatim: device.name)
                        .tag(device)
                }
            }
        }
        .task {
            for await microphones in CaptureDevice.DiscoveryService(mediaType: .audio, deviceTypes: [.microphone]).devices {
                self.microphones = microphones
            }
        }
    }
}

#Preview {
    AudioControlSection()
        .environment(StreamConfiguration())
}
