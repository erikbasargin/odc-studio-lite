//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import AudioVideoKit

final class MockDevice: NSObject, CaptureDeviceProtocol {
    
    enum Record: Equatable, Sendable {
        case addObserver(keyPath: String, options: NSKeyValueObservingOptions, withContext: Bool)
        case removeObserver(keyPath: String, withContext: Bool)
        case userPreferredCameraDidChange(id: String?)
    }
    
    nonisolated(unsafe) static var kvoEventsHandler: AsyncStream<Record>.Continuation?
    
    @objc static nonisolated(unsafe) var systemPreferredCamera: MockDevice? {
        willSet {
            willChangeValue(forKey: "systemPreferredCamera")
        }
        didSet {
            didChangeValue(forKey: "systemPreferredCamera")
        }
    }
    
    @objc static nonisolated(unsafe) var userPreferredCamera: MockDevice? {
        willSet {
            willChangeValue(forKey: "userPreferredCamera")
        }
        didSet {
            didChangeValue(forKey: "userPreferredCamera")
            kvoEventsHandler?.yield(.userPreferredCameraDidChange(id: userPreferredCamera?.uniqueID))
        }
    }
    
    let uniqueID: String
    let localizedName: String
        
    override class func addObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        options: NSKeyValueObservingOptions = [],
        context: UnsafeMutableRawPointer?
    ) {
        kvoEventsHandler?.yield(
            .addObserver(
                keyPath: keyPath,
                options: options,
                withContext: context != nil
            )
        )
        super.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
    }
    
    override class func removeObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        context: UnsafeMutableRawPointer?
    ) {
        kvoEventsHandler?.yield(
            .removeObserver(
                keyPath: keyPath,
                withContext: context != nil
            )
        )
        super.removeObserver(observer, forKeyPath: keyPath, context: context)
    }
    
    init(uniqueID: String) {
        self.uniqueID = uniqueID
        self.localizedName = ""
    }

    init(uniqueID: String, localizedName: String) {
        self.uniqueID = uniqueID
        self.localizedName = localizedName
    }
}