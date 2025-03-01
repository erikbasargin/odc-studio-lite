//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation

public struct CaptureDevice: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

extension CaptureDevice {

    init<Device>(device: Device) where Device: CaptureDeviceProtocol {
        self.id = device.uniqueID
        self.name = device.localizedName
    }
}
