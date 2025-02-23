//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import Foundation
import Testing

@Suite(.serialized, .timeLimit(.minutes(1)))
struct PreferredCameraProviderTests {
    
    private let keyPath = "systemPreferredCamera"
    
    init() {
        MockDevice.systemPreferredCamera = nil
        MockDevice.userPreferredCamera = nil
    }
    
    @Test func systemPreferredCameraKVOObserver() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: MockDevice.Record.self)
        defer { continuation.finish() }
        
        MockDevice.kvoEventsHandler = continuation
        
        _ = PreferredCameraProvider(sourceType: MockDevice.self)
        
        let records = await stream.prefix(2).reduce(into: []) { partialResult, record in
            partialResult.append(record)
        }
        
        #expect(
            records == [
                .addObserver(keyPath: keyPath, options: [.old, .new], withContext: false),
                .removeObserver(keyPath: keyPath, withContext: false),
            ]
        )
    }
    
    @Test func preferredCameraUpdates() async throws {
        let observer = PreferredCameraProvider(sourceType: MockDevice.self)
        
        async let cameraObserver = observer.preferredCamera.prefix(3).reduce(into: []) { partialResult, camera in
            partialResult.append(camera)
        }
        
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        await Task.megaYield()
        MockDevice.systemPreferredCamera = nil
        await Task.megaYield()
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "2")
        
        let cameras = await cameraObserver
        
        #expect(
            cameras == [
                CaptureDevice(id: "1", name: ""),
                nil,
                CaptureDevice(id: "2", name: ""),
            ]
        )
    }
    
    @Test func preferredCameraRetainsLatestValue() async throws {
        let observer = PreferredCameraProvider(sourceType: MockDevice.self)
        
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        await Task.megaYield()
        MockDevice.systemPreferredCamera = nil
        await Task.megaYield()
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "2")
        
        let camera = await observer.preferredCamera.first(where: { _ in true })
        
        #expect(camera == CaptureDevice(id: "2", name: ""))
    }
    
    @Test func systemPreferredCameraUpdatesAreDistinct() async throws {
        let observer = PreferredCameraProvider(sourceType: MockDevice.self)
        
        async let cameraObserver = observer.preferredCamera.prefix(2).reduce(into: []) { partialResult, camera in
            partialResult.append(camera)
        }
        
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        await Task.megaYield()
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        await Task.megaYield()
        MockDevice.systemPreferredCamera = nil
        
        let cameras = await cameraObserver
        
        #expect(
            cameras == [
                CaptureDevice(id: "1", name: ""),
                nil,
            ]
        )
    }
    
    @Test func onNextDoesNotEmitValueWhenNotSystemPreferredCameraKeypathObserved() async throws {
        let observer = PreferredCameraProvider(sourceType: MockDevice.self)
        
        async let cameraObserver = observer.preferredCamera.prefix(1).reduce(into: []) { partialResult, deviceID in
            partialResult.append(deviceID)
        }
        
        MockDevice.userPreferredCamera = MockDevice(uniqueID: "2")
        await Task.megaYield()
        MockDevice.userPreferredCamera = nil
        await Task.megaYield()
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        
        let cameras = await cameraObserver
        
        #expect(
            cameras == [
                CaptureDevice(id: "1", name: "")
            ]
        )
    }
}

private final class MockDevice: NSObject, CaptureDeviceProtocol {
    
    enum Record: Equatable, Sendable {
        case addObserver(keyPath: String, options: NSKeyValueObservingOptions, withContext: Bool)
        case removeObserver(keyPath: String, withContext: Bool)
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
        }
    }
    
    let uniqueID: String
    
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
    }
}

extension Task where Success == Never, Failure == Never {
    
    fileprivate static func megaYield() async {
        for _ in 0..<50 {
            await Task.yield()
        }
    }
}
