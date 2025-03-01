//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import AVFoundation

extension CaptureDevice {

    package struct VideoDiscoveryService<Session: CaptureDeviceDiscoverySession>: CaptureDeviceDiscoveryService {
        
        public var devices: AsyncStream<[CaptureDevice]> {
            observer.stream
        }
        
        private let observer: Observer

        package init(
            session: Session = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .continuityCamera],
                mediaType: .video,
                position: .unspecified
            )
        ) {
            observer = Observer(session: session)
        }
    }
}

fileprivate extension CaptureDevice.VideoDiscoveryService {
    final class Observer: NSObject {
        let stream: AsyncStream<[CaptureDevice]>
        private let continuation: AsyncStream<[CaptureDevice]>.Continuation
        private let session: Session
        private let keyPath = "devices"
        
        init(session: Session) {
            (stream, continuation) = AsyncStream.makeStream(of: [CaptureDevice].self)
            self.session = session
            super.init()
            session.addObserver(self, forKeyPath: keyPath, options: [.initial, .old, .new], context: nil)
        }

        deinit {
            session.removeObserver(self, forKeyPath: keyPath)
        }

        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            precondition(keyPath == self.keyPath)

            func makeSet(from devices: [Session.Device]) -> Set<CaptureDevice> {
                Set(devices.map(CaptureDevice.init(device:)))
            }
            
            let oldDevices = (change?[.oldKey] as? [Session.Device]).flatMap(makeSet(from:))
            let newDevices = (change?[.newKey] as? [Session.Device]).flatMap(makeSet(from:))
            
            switch (oldDevices, newDevices) {
            case (nil, nil):
                assertionFailure("No devices observed")
                break
            case let (old, new?) where new != old:
                continuation.yield(Array(new))
            default:
                break
            }
        }
    }
}

extension AVCaptureDevice.DiscoverySession: CaptureDeviceDiscoverySession {}
