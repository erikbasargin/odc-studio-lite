//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import ScreenCaptureKit

package protocol CaptureDeviceProtocol: NSObject {
    var uniqueID: String { get }
}

package final class PreferredCameraObserver<Source: CaptureDeviceProtocol>: NSObject {
    
    private let keyPath = "systemPreferredCamera"
    private let onNext: (Source?) -> Void
    
    package init(sourceType: Source.Type = Source.self, onNext: @escaping (Source?) -> Void) {
        self.onNext = onNext
        super.init()
        
        Source.self.addObserver(self, forKeyPath: keyPath, options: [.old, .new], context: nil)
    }
    
    deinit {
        Source.self.removeObserver(self, forKeyPath: keyPath, context: nil)
    }
    
    package override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        precondition(keyPath == self.keyPath)
        
        let oldSource = change?[.oldKey] as? Source
        let newSource = change?[.newKey] as? Source
        
        if oldSource?.uniqueID != newSource?.uniqueID {
            onNext(newSource)
        }
    }
}

extension AVCaptureDevice: CaptureDeviceProtocol {}
