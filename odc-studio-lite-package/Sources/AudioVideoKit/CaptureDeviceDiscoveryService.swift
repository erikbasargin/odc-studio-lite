//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation

package protocol CaptureDeviceDiscoveryService {
    var devices: AsyncStream<[CaptureDevice]> { get }
}

package protocol CaptureDeviceDiscoverySession: NSObject {
    associatedtype Device: CaptureDeviceProtocol
    var devices: [Device] { get }
}
