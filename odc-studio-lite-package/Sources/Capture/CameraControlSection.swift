//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import SwiftUI

public struct CameraControlSection: View {
    
    @Environment(CameraControl.self) private var cameraControl
    
    public var body: some View {
        @Bindable var cameraControl = self.cameraControl
        
        Section("Video") {
            Picker(
                "Camera - \(cameraControl.selectedCamera?.name ?? "not selected")",
                selection: $cameraControl.selectedCamera
            ) {
                ForEach(cameraControl.listOfCameras) { device in
                    Text(verbatim: device.name)
                        .tag(device)
                }
            }
        }
        .task {
            await cameraControl.listenForCameras()
        }
    }
}

//#Preview {
//    CameraControlSection()
//        .environment(CameraControl())
//}
