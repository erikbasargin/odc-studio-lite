import ComposableArchitecture
@testable import ODCLite
import AudioVideoKit
import Testing

@Suite
struct BroadcastFeatureTests {

    @Test
    @MainActor
    func taskObservesSnapshotUpdates() async {
        let initialSnapshot = BroadcastStateSnapshot(
            bandwidthTestEnabled: false,
            primaryStreamKey: "initial-key",
            isBroadcasting: false,
            cameraIsAuthorized: false,
            selectedCamera: nil,
            selectedMicrophone: nil
        )
        let updatedSnapshot = BroadcastStateSnapshot(
            bandwidthTestEnabled: true,
            primaryStreamKey: "updated-key",
            isBroadcasting: true,
            cameraIsAuthorized: true,
            selectedCamera: CaptureDevice(id: "camera-1", name: "FaceTime HD Camera"),
            selectedMicrophone: CaptureDevice(id: "microphone-1", name: "MacBook Pro Microphone")
        )
        let probe = BroadcastClientProbe()
        let (updates, continuation) = AsyncStream.makeStream(of: BroadcastStateSnapshot.self)
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                bootstrap: {
                    await probe.recordBootstrap()
                },
                snapshot: {
                    initialSnapshot
                },
                updates: {
                    updates
                }
            )
        }

        await store.send(.task)
        await store.receive(.stateDidChange(initialSnapshot))

        continuation.yield(updatedSnapshot)

        await store.receive(.stateDidChange(updatedSnapshot)) {
            $0 = BroadcastFeature.State(snapshot: updatedSnapshot)
        }

        continuation.finish()
        await store.finish()

        #expect(await probe.bootstrapCount() == 0)
    }

    @Test
    @MainActor
    func bandwidthTestFlagWritesThroughDependency() async {
        let probe = BroadcastClientProbe()
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                setBandwidthTestEnabled: { isEnabled in
                    await probe.recordBandwidthTestEnabled(isEnabled)
                }
            )
        }

        await store.send(.bandwidthTestEnabledChanged(true)) {
            $0.bandwidthTestEnabled = true
        }
        await store.finish()

        #expect(await probe.bandwidthTestValues() == [true])
    }

    @Test
    @MainActor
    func availableCamerasAreReducerOwned() async {
        let cameras = [CaptureDevice(id: "camera-1", name: "FaceTime HD Camera")]
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        }

        await store.send(.availableCamerasChanged(cameras)) {
            $0.availableCameras = cameras
        }
    }

    @Test
    @MainActor
    func availableMicrophonesAreReducerOwned() async {
        let microphones = [CaptureDevice(id: "microphone-1", name: "MacBook Pro Microphone")]
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        }

        await store.send(.availableMicrophonesChanged(microphones)) {
            $0.availableMicrophones = microphones
        }
    }

    @Test
    @MainActor
    func selectedCameraWritesThroughDependency() async {
        let probe = BroadcastClientProbe()
        let camera = CaptureDevice(id: "camera-1", name: "FaceTime HD Camera")
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                setSelectedCamera: { selectedCamera in
                    await probe.recordSelectedCamera(selectedCamera)
                }
            )
        }

        await store.send(.selectedCameraChanged(camera)) {
            $0.selectedCamera = camera
        }
        await store.finish()

        #expect(await probe.selectedCameraValues() == [camera])
    }

    @Test
    @MainActor
    func selectedMicrophoneWritesThroughDependency() async {
        let probe = BroadcastClientProbe()
        let microphone = CaptureDevice(id: "microphone-1", name: "MacBook Pro Microphone")
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                setSelectedMicrophone: { selectedMicrophone in
                    await probe.recordSelectedMicrophone(selectedMicrophone)
                }
            )
        }

        await store.send(.selectedMicrophoneChanged(microphone)) {
            $0.selectedMicrophone = microphone
        }
        await store.finish()

        #expect(await probe.selectedMicrophoneValues() == [microphone])
    }

    @Test
    @MainActor
    func toggleBroadcastWritesThroughDependency() async {
        let probe = BroadcastClientProbe()
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                toggleBroadcast: {
                    await probe.recordToggleBroadcast()
                }
            )
        }

        await store.send(.startStopBroadcastButtonTapped)
        await store.finish()

        #expect(await probe.toggleBroadcastCount() == 1)
    }
}
