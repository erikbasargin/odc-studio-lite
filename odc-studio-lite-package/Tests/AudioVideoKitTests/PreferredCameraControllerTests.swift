//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import Foundation
import Testing
import os

@Suite(.serialized, .timeLimit(.minutes(1)))
struct PreferredCameraControllerTests {
    
    private let keyPath = "systemPreferredCamera"
    
    init() {
        MockDevice.kvoEventsHandler = nil
        MockDevice.systemPreferredCamera = nil
        MockDevice.userPreferredCamera = nil
    }
    
    @Test func initialPreferredCamera() async throws {
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1", localizedName: "Camera")
        
        let controller = PreferredCameraController(sourceType: MockDevice.self)
        let preferredCamera = await controller.preferredCamera.first(where: { _ in true })
        
        #expect(preferredCamera == CaptureDevice(id: "1", name: "Camera"))
    }
    
    @Test func systemPreferredCameraKVOObserver() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: MockDevice.Record.self)
        defer { continuation.finish() }
        
        MockDevice.kvoEventsHandler = continuation
        
        _ = PreferredCameraController(sourceType: MockDevice.self)
        
        let records = await stream.prefix(2).reduce(into: []) { partialResult, record in
            partialResult.append(record)
        }
        
        #expect(
            records == [
                .addObserver(keyPath: keyPath, options: [.initial, .old, .new], withContext: false),
                .removeObserver(keyPath: keyPath, withContext: false),
            ]
        )
    }
    
    @Test(
        """
        When setPreferredCamera is called, \
        Then userPreferredCamera is updated
        """
    )
    func userPreferredCameraIsUpdated() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: MockDevice.Record.self)
        defer { continuation.finish() }
        
        MockDevice.kvoEventsHandler = continuation
        
        let controller = PreferredCameraController(sourceType: MockDevice.self)
        
        async let recordsObserver = stream.dropFirst().prefix(2).reduce(into: []) { partialResult, record in
            partialResult.append(record)
        }
        
        controller.setPreferredCamera(CaptureDevice(id: "1", name: ""))
        await Task.megaYield()
        controller.setPreferredCamera(nil)
        await Task.megaYield()
        
        let records = await recordsObserver
        
        #expect(
            records == [
                .userPreferredCameraDidChange(id: "1"),
                .userPreferredCameraDidChange(id: nil),
            ]
        )
    }
    
    @Test func preferredCameraUpdates() async throws {
        let observer = PreferredCameraController(sourceType: MockDevice.self)
        
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
        let observer = PreferredCameraController(sourceType: MockDevice.self)
        
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "1")
        await Task.megaYield()
        MockDevice.systemPreferredCamera = nil
        await Task.megaYield()
        MockDevice.systemPreferredCamera = MockDevice(uniqueID: "2")
        
        let camera = await observer.preferredCamera.first(where: { _ in true })
        
        #expect(camera == CaptureDevice(id: "2", name: ""))
    }
    
    @Test func systemPreferredCameraUpdatesAreDistinct() async throws {
        let observer = PreferredCameraController(sourceType: MockDevice.self)
        
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
        let observer = PreferredCameraController(sourceType: MockDevice.self)
        
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

    @Test func streamIsClosedWhenControllerIsDeallocated() async throws {
        let controller: OSAllocatedUnfairLock<PreferredCameraController<MockDevice>?> = OSAllocatedUnfairLock(
            uncheckedState: PreferredCameraController(sourceType: MockDevice.self)
        )
        
        async let stream = try controller.withLock { 
            let controller = try #require($0)
            return controller.preferredCamera
        }
        
        await Task.megaYield()
        
        controller.withLock { $0 = nil }

        let result = try await stream.first { _ in true }
        
        #expect(result == nil)
    }
}
