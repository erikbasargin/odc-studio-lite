//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import AVFoundation

extension CaptureDevice {

    package typealias MediaType = AVMediaType
    package typealias DeviceType = AVCaptureDevice.DeviceType

    package struct DiscoveryService<Session: CaptureDeviceDiscoverySession>: CaptureDeviceDiscoveryService {
        
        public var devices: AsyncStream<[CaptureDevice]> {
            observer.stream
        }
        
        private let observer: Observer
        
        package init(mediaType: MediaType, deviceTypes: [DeviceType]) where Session == AVCaptureDevice.DiscoverySession {
            self.init(mediaType: mediaType, deviceTypes: deviceTypes, sessionFactory: Session.init(mediaType:deviceTypes:))
        }
        
        init(mediaType: MediaType, deviceTypes: [DeviceType], sessionFactory: (MediaType, [DeviceType]) -> Session) {
            observer = Observer(session: sessionFactory(mediaType, deviceTypes))
        }
    }
}

fileprivate extension CaptureDevice.DiscoveryService {
    final class Observer: NSObject {
        let stream: AsyncStream<[CaptureDevice]>
        private let continuation: AsyncStream<[CaptureDevice]>.Continuation
        private let session: Session
        private let keyPath = "devices"
        
        init(session: Session) {
            (stream, continuation) = AsyncStream.makeStream(of: [CaptureDevice].self, bufferingPolicy: .bufferingNewest(1))
            self.session = session
            super.init()
            session.addObserver(self, forKeyPath: keyPath, options: [.initial, .new], context: nil)
        }

        deinit {
            continuation.finish()
            session.removeObserver(self, forKeyPath: keyPath)
        }

        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            precondition(keyPath == self.keyPath)
            
            guard let devices = (change?[.newKey] as? [Session.Device]) else {
                assertionFailure("No devices observed")
                return
            }
            
            continuation.yield(devices.map(CaptureDevice.init(device:)))
        }
    }
}

extension AVCaptureDevice.DiscoverySession: CaptureDeviceDiscoverySession {}


fileprivate extension AVCaptureDevice.DiscoverySession {

    convenience init(mediaType: CaptureDevice.MediaType, deviceTypes: [CaptureDevice.DeviceType]) {
        self.init(deviceTypes: deviceTypes, mediaType: mediaType, position: .unspecified)
    }
}
