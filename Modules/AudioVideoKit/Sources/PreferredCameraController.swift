//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import ScreenCaptureKit

public protocol CaptureDeviceProtocol<Camera>: NSObject {
    
    associatedtype Camera: CaptureDeviceProtocol
    
    static var userPreferredCamera: Camera? { get set }
    
    var uniqueID: String { get }
    var localizedName: String { get }
    
    init?(uniqueID: String)
}

public protocol PreferredCameraControlling {
    
    associatedtype Source: CaptureDeviceProtocol
    
    var preferredCamera: AsyncStream<CaptureDevice?> { get }
    
    func setPreferredCamera(_ preferredCamera: CaptureDevice?)
}

public protocol PreferredCameraProviding {
    associatedtype Source: CaptureDeviceProtocol
    var preferredCamera: AsyncStream<CaptureDevice?> { get }
}

public struct PreferredCameraController<Source: CaptureDeviceProtocol>: PreferredCameraControlling {
    
    public var preferredCamera: AsyncStream<CaptureDevice?> {
        observer.preferredCamera
    }
    
    private let observer: Observer
    
    public init(sourceType: Source.Type = AVCaptureDevice.self) {
        self.observer = Observer()
    }
    
    public func setPreferredCamera(_ preferredCamera: CaptureDevice?) {
        Source.userPreferredCamera =
            if let id = preferredCamera?.id {
                Source.Camera(uniqueID: id)
            } else {
                nil
            }
    }
}

extension PreferredCameraController {
    
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
            Source.self.addObserver(self, forKeyPath: keyPath, options: [.initial, .new], context: nil)
        }
        
        deinit {
            continuation.finish()
            Source.self.removeObserver(self, forKeyPath: keyPath, context: nil)
        }
        
        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            precondition(keyPath == self.keyPath)
            
            guard let newValue = change?[.newKey] else {
                preconditionFailure("No preferred camera observed")
            }
            
            let captureDevice = (newValue as? Source).map(CaptureDevice.init(device:))
            
            continuation.yield(captureDevice)
        }
    }
}

extension AVCaptureDevice: CaptureDeviceProtocol {}
