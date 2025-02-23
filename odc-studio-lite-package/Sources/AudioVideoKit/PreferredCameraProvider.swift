//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import ScreenCaptureKit

package protocol CaptureDeviceProtocol: NSObject {
    var uniqueID: String { get }
}

package protocol PreferredCameraProviding {
    associatedtype Source: CaptureDeviceProtocol
    var preferredCamera: AsyncStream<CaptureDevice?> { get }
}

package struct PreferredCameraProvider<Source: CaptureDeviceProtocol>: PreferredCameraProviding {
    
    package var preferredCamera: AsyncStream<CaptureDevice?> {
        observer.preferredCamera
    }
    
    private let observer: Observer
    
    package init(sourceType: Source.Type = AVCaptureDevice.self) {
        self.observer = Observer()
    }
}

extension PreferredCameraProvider {
    
    private final class Observer: NSObject {
        
        let preferredCamera: AsyncStream<CaptureDevice?>
        
        private let continuation: AsyncStream<CaptureDevice?>.Continuation
        private let keyPath = "systemPreferredCamera"
        
        override init() {
            (preferredCamera, continuation) = AsyncStream.makeStream(
                of: CaptureDevice?.self,
                bufferingPolicy: .bufferingNewest(1)
            )
            super.init()
            Source.self.addObserver(self, forKeyPath: keyPath, options: [.old, .new], context: nil)
        }
        
        deinit {
            Source.self.removeObserver(self, forKeyPath: keyPath, context: nil)
        }
        
        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            precondition(keyPath == self.keyPath)
            
            let oldSource = change?[.oldKey] as? Source
            let newSource = change?[.newKey] as? Source
            
            if oldSource?.uniqueID != newSource?.uniqueID {
                let captureDevice = newSource.map { source in
                    CaptureDevice(id: source.uniqueID, name: "")
                }
                continuation.yield(captureDevice)
            }
        }
    }
}

extension AVCaptureDevice: CaptureDeviceProtocol {}
