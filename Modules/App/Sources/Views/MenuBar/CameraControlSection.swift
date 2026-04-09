//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import SwiftUI
import AudioVideoKit

struct CameraControlSection: View {
    
    @Environment(StreamConfiguration.self) private var streamConfiguration
    @State private var cameras: [CaptureDevice] = []
    
    var body: some View {
        @Bindable var streamConfiguration = self.streamConfiguration
        
        Section("Video") {
            Picker(
                "Camera - \(streamConfiguration.selectedCamera?.name ?? "not selected")",
                selection: $streamConfiguration.selectedCamera
            ) {
                ForEach(cameras) { device in
                    Text(verbatim: device.name)
                        .tag(device)
                }
            }
        }
        .task {
            let discoveryService = CaptureDevice.DiscoveryService(
                mediaType: .video, 
                deviceTypes: [.builtInWideAngleCamera, .continuityCamera]
            )
            for await cameras in discoveryService.devices {
                self.cameras = cameras
            }
        }
    }
}

#Preview {
    CameraControlSection()
        .environment(StreamConfiguration())
}
