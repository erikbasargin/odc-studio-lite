//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import SwiftUI
import AudioVideoKit
public struct CameraControlSection: View {
    
    @State private var selectedCamera: CaptureDevice?
    @State private var cameras: [CaptureDevice] = []

    public init() {}
    
    public var body: some View {
        Section("Video") {
            Picker(
                "Camera - \(selectedCamera?.name ?? "not selected")",
                selection: $selectedCamera
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
}
