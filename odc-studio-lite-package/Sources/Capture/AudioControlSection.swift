//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import SwiftUI

public struct AudioControlSection: View {
    
    @Environment(AudioControl.self) private var audioControl
    
    public var body: some View {
        @Bindable var audioControl = audioControl
        
        Section("Audio") {
            Toggle("Capture microphone", isOn: $audioControl.captureMicrophone)
        }
    }
}

#Preview {
    AudioControlSection()
        .environment(AudioControl())
}
