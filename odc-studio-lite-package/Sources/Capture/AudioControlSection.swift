//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import SwiftUI

public struct AudioControlSection: View {
    
    @Environment(AudioControl.self) private var audioControl
    
    public init() {}
    
    public var body: some View {
        @Bindable var audioControl = self.audioControl
        
        Section("Audio") {
            Picker(
                "Microphone - \(audioControl.selectedMicrophone?.name ?? "not selected")",
                selection: $audioControl.selectedMicrophone
            ) {
                ForEach(audioControl.listOfMicrophones) { device in
                    Text(verbatim: device.name)
                        .tag(device)
                }
            }
        }
        .task {
            await audioControl.listenForMicrophones()
        }
    }
}

#Preview {
    AudioControlSection()
        .environment(AudioControl())
}
