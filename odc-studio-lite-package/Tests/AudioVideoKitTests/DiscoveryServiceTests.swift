//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import Testing
import os
import ConcurrencyExtras

@testable import AudioVideoKit

@Suite(.timeLimit(.minutes(1)))
struct DiscoveryServiceTests {

    fileprivate let mockDiscoverySession = MockDiscoverySession()

    @Test
    func initialVideoDevices() async throws {
        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "1", localizedName: "Camera 1"),
        ])

        let service = makeService()
        
        for await devices in service.devices.prefix(1) {
            #expect(
                devices == [
                    CaptureDevice(id: "1", name: "Camera 1"),
                ]
            )
        }
    }

    @Test
    func videoDeviceTypes() async throws {
        await confirmation { confirmation in
            let _ = CaptureDevice.DiscoveryService(
                mediaType: .video,
                deviceTypes: [.continuityCamera], 
                sessionFactory: { mediaType, deviceTypes in 
                    #expect(mediaType == .video)
                    #expect(deviceTypes == [.continuityCamera])
                    confirmation()
                    return mockDiscoverySession
                }
            )
        }
    }
    
    @Test("""
    When video devices are discovered, \
    Then they are returned in the devices stream.
    """)
    func videoDevicesAreDiscovered() async throws {
        let service = makeService()
        let devices = service.devices
        
        async let events = devices.dropFirst().prefix(2).reduce(into: []) { partialResult, devices in
            partialResult.append(devices)
        }.map { devices in
            devices.sorted { $0.id < $1.id }
        }

        await Task.megaYield()
        
        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "1", localizedName: "Camera 1"),
        ])
        
        await Task.megaYield()

        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "1", localizedName: "Camera 1"),
            MockDevice(uniqueID: "2", localizedName: "Camera 2"),
        ])

        await #expect(
            events == [
                [
                    CaptureDevice(id: "1", name: "Camera 1"),
                ],
                [
                    CaptureDevice(id: "1", name: "Camera 1"),
                    CaptureDevice(id: "2", name: "Camera 2"),
                ],
            ]
        )
    }

    @Test func devicesRetainsLatestValue() async throws {
        let service = makeService()

        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "1", localizedName: "Camera 1"),
        ])

        await Task.megaYield()

        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "2", localizedName: "Camera 2"),
        ])

        await Task.megaYield()

        for await devices in service.devices.prefix(1) {
            #expect(
                devices == [
                    CaptureDevice(id: "2", name: "Camera 2"),
                ]
            )
        }
    }

    @Test func streamIsClosedWhenSessionIsDeallocated() async throws {
        let service: OSAllocatedUnfairLock<CaptureDevice.DiscoveryService<MockDiscoverySession>?> = OSAllocatedUnfairLock(uncheckedState: makeService())

        async let stream = try service.withLock {
            let service = try #require($0)
            return service.devices
        }
        
        await Task.megaYield()

        service.withLock { $0 = nil }

        let result = try await stream.dropFirst().first { _ in true }

        #expect(result == nil)
    }
}

private extension DiscoveryServiceTests {

    func makeService(
        mediaType: CaptureDevice.MediaType = .video, 
        deviceTypes: [CaptureDevice.DeviceType] = []) -> CaptureDevice.DiscoveryService<MockDiscoverySession> {
        CaptureDevice.DiscoveryService(mediaType: mediaType, deviceTypes: deviceTypes, sessionFactory: { _, _ in mockDiscoverySession })
    }
}

private final class MockDiscoverySession: NSObject, CaptureDeviceDiscoverySession {
    
    @objc dynamic private(set) var devices: [MockDevice] = []
    
    func stubDiscoveredDevices(_ devices: [MockDevice]) {
        self.devices = devices
    }
}
