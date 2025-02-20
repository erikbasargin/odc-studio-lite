//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import Testing
import AVFoundation
import AudioVideoKit

@Suite(.serialized, .timeLimit(.minutes(1)))
struct PreferredCameraObserverTests {
    
    private let keyPath = "systemPreferredCamera"
    
    @Test func systemPreferredCameraKVOObserver() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: MockDevice.Record.self)
        defer { continuation.finish() }
        
        MockDevice.kvoEventsHandler = continuation
        
        _ = PreferredCameraObserver(sourceType: MockDevice.self, onNext: { _ in })
        
        let records = await stream.prefix(2).reduce(into: []) { partialResult, record in
            partialResult.append(record)
        }
        
        #expect(records == [
            .addObserver(keyPath: keyPath, options: [.old, .new], withContext: false),
            .removeObserver(keyPath: keyPath, withContext: false),
        ])
    }
    
    @Test func systemPreferredCameraUpdates() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: String?.self)
        defer { continuation.finish() }
        
        let observer = PreferredCameraObserver(sourceType: MockDevice.self) { device in
            continuation.yield(device?.uniqueID)
        }
        
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        MockDevice.systemPreferredCamera = nil
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "2")
        
        let deviceIDs = await stream.prefix(3).reduce(into: []) { partialResult, deviceID in
            partialResult.append(deviceID)
        }
        
        #expect(deviceIDs == ["1", nil, "2"])
        print(observer.description)
    }
    
    @Test func systemPreferredCameraUpdatesAreDistinct() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: String?.self)
        defer { continuation.finish() }
        
        let observer = PreferredCameraObserver(sourceType: MockDevice.self) { device in
            continuation.yield(device?.uniqueID)
        }
        
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        MockDevice.systemPreferredCamera = nil
        
        let deviceIDs = await stream.prefix(2).reduce(into: []) { partialResult, deviceID in
            partialResult.append(deviceID)
        }
        
        #expect(deviceIDs == ["1", nil])
        print(observer.description)
    }
    
    @Test func onNextDoesNotEmitValueWhenNotSystemPreferredCameraKeypathObserved() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: String?.self)
        defer { continuation.finish() }
        
        let observer = PreferredCameraObserver(sourceType: MockDevice.self) { device in
            continuation.yield(device?.uniqueID)
        }
        
        MockDevice.userPreferredCamera = MockDevice(uniqueID: "2")
        MockDevice.userPreferredCamera = nil
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        
        let deviceIDs = await stream.prefix(1).reduce(into: []) { partialResult, deviceID in
            partialResult.append(deviceID)
        }
        
        #expect(deviceIDs == ["1"])
        print(observer.description)
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
