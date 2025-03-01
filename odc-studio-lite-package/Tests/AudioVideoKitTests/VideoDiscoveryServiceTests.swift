//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation
import Testing
import AudioVideoKit

@Suite(.timeLimit(.minutes(1)))
struct VideoDiscoveryServiceTests {

    fileprivate let mockDiscoverySession = MockDiscoverySession()

    @Test
    func initialVideoDevices() async throws {
        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "1", localizedName: "Camera 1"),
        ])

        let service = CaptureDevice.VideoDiscoveryService(session: mockDiscoverySession)
        
        for await devices in service.devices.prefix(1) {
            #expect(
                devices == [
                    CaptureDevice(id: "1", name: "Camera 1"),
                ]
            )
        }
    }
    
    @Test("""
    When video devices are discovered, \
    Then they are returned in the devices stream.
    """)
    func videoDevicesAreDiscovered() async throws {
        let service = CaptureDevice.VideoDiscoveryService(session: mockDiscoverySession)
        let devices = service.devices
        
        async let events = devices.dropFirst().prefix(2).reduce(into: []) { partialResult, devices in
            partialResult.append(devices)
        }.map { devices in
            devices.sorted { $0.id < $1.id }
        }
        
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

    @Test func videoDevicesAreDistinct() async throws {
        let service = CaptureDevice.VideoDiscoveryService(session: mockDiscoverySession)
        let devices = service.devices
        
        async let events = devices.dropFirst().prefix(2).reduce(into: []) { partialResult, devices in
            partialResult.append(devices)
        }.map { devices in
            devices.sorted { $0.id < $1.id }
        }
        
        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "1"),
            MockDevice(uniqueID: "2"),
        ])
        
        await Task.megaYield()

        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "2"),
            MockDevice(uniqueID: "1"),
        ])

        await Task.megaYield()

        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "1"),
            MockDevice(uniqueID: "2"),
            MockDevice(uniqueID: "3"),
        ])

        await #expect(
            events == [
                [
                    CaptureDevice(id: "1", name: ""),
                    CaptureDevice(id: "2", name: ""),
                ],
                [
                    CaptureDevice(id: "1", name: ""),
                    CaptureDevice(id: "2", name: ""),
                    CaptureDevice(id: "3", name: ""),
                ],
            ]
        )
    }

    @Test func videoDevicesAreUnique() async throws {
        let service = CaptureDevice.VideoDiscoveryService(session: mockDiscoverySession)
        let devices = service.devices
        
        async let events = devices.dropFirst().prefix(1).reduce(into: []) { partialResult, devices in
            partialResult.append(devices)
        }.map { devices in
            devices.sorted { $0.id < $1.id }
        }
        
        mockDiscoverySession.stubDiscoveredDevices([
            MockDevice(uniqueID: "2"),
            MockDevice(uniqueID: "1"),
            MockDevice(uniqueID: "1"),
            MockDevice(uniqueID: "2"),
        ])
        
        await #expect(
            events == [
                [
                    CaptureDevice(id: "1", name: ""),
                    CaptureDevice(id: "2", name: ""),
                ]
            ]
        )
    }

    @Test func devicesRetainsLatestValue() async throws {
        let service = CaptureDevice.VideoDiscoveryService(session: mockDiscoverySession)

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
}
private final class MockDiscoverySession: NSObject, CaptureDeviceDiscoverySession {
    
    @objc dynamic private(set) var devices: [MockDevice] = []
    
    func stubDiscoveredDevices(_ devices: [MockDevice]) {
        self.devices = devices
    }
}
