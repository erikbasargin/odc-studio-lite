//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import SwiftUI
import AudioVideoKit
public struct AudioControlSection: View {
    
    @State private var selectedMicrophone: CaptureDevice?
    @State private var microphones: [CaptureDevice] = []
    
    public init() {}
    
    public var body: some View {
        Section("Audio") {
            Picker(
                "Microphone - \(selectedMicrophone?.name ?? "not selected")",
                selection: $selectedMicrophone
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
}
