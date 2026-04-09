//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation

public protocol CaptureDeviceDiscoveryService {
    var devices: AsyncStream<[CaptureDevice]> { get }
}

public protocol CaptureDeviceDiscoverySession: NSObject {
    associatedtype Device: CaptureDeviceProtocol
    var devices: [Device] { get }
}
