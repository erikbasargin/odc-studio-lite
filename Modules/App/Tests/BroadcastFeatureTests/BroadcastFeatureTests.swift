import AudioVideoKit
import ComposableArchitecture
@testable import ODCLite
import Testing

@Suite
struct BroadcastFeatureTests {

    @Test
    @MainActor
    func taskHasNoBootstrapSideEffects() async {
        let probe = BroadcastClientProbe()
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                bootstrap: { selectedMicrophone in
                    await probe.recordBootstrap(selectedMicrophone: selectedMicrophone)
                    return false
                }
            )
        }

        await store.send(.task)
        await store.finish()

        #expect(await probe.bootstrapCount() == 0)
    }

    @Test
    @MainActor
    func bandwidthTestFlagIsReducerOwned() async {
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        }

        await store.send(.bandwidthTestEnabledChanged(true)) {
            $0.bandwidthTestEnabled = true
        }
    }

    @Test
    @MainActor
    func microphoneCaptureDisablesSelectedMicrophone() async {
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

        store.exhaustivity = .off

        await store.send(.selectedMicrophoneChanged(microphone)) {
            $0.selectedMicrophone = microphone
        }
        await store.send(.captureMicrophoneChanged(false)) {
            $0.selectedMicrophone = nil
        }
        await store.finish()

        #expect(await probe.selectedMicrophoneValues() == [microphone, nil])
    }

    @Test
    @MainActor
    func microphoneCaptureEnablesDefaultMicrophone() async {
        let probe = BroadcastClientProbe()
        let microphone = CaptureDevice(id: "microphone-1", name: "MacBook Pro Microphone")
        await probe.setDefaultMicrophone(microphone)
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                defaultMicrophone: {
                    await probe.resolveDefaultMicrophone()
                },
                setSelectedMicrophone: { selectedMicrophone in
                    await probe.recordSelectedMicrophone(selectedMicrophone)
                }
            )
        }

        await store.send(.captureMicrophoneChanged(true))
        await store.receive(.defaultMicrophoneResolved(microphone)) {
            $0.selectedMicrophone = microphone
        }
        await store.finish()

        #expect(await probe.selectedMicrophoneValues() == [microphone])
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
    func startBroadcastUsesExplicitPrimaryStreamKey() async {
        let probe = BroadcastClientProbe()
        let microphone = CaptureDevice(id: "microphone-1", name: "MacBook Pro Microphone")
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                startBroadcast: { primaryStreamKey, selectedMicrophone, _ in
                    await probe.recordStartBroadcast(
                        primaryStreamKey: primaryStreamKey,
                        selectedMicrophone: selectedMicrophone
                    )
                }
            )
        }

        await store.send(.selectedMicrophoneChanged(microphone)) {
            $0.selectedMicrophone = microphone
        }
        await store.send(.startStopBroadcastButtonTapped("stream-key")) {
            $0.isBroadcasting = true
        }
        await store.finish()

        let requests = await probe.startBroadcastValues()
        #expect(requests.count == 1)
        #expect(requests.first?.primaryStreamKey == "stream-key")
        #expect(requests.first?.selectedMicrophone == microphone)
    }

    @Test
    @MainActor
    func stopBroadcastWritesThroughDependency() async {
        let probe = BroadcastClientProbe()
        let store = TestStore(
            initialState: BroadcastFeature.State(configuration: .init(isBroadcasting: true))
        ) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                stopBroadcast: {
                    await probe.recordStopBroadcast()
                }
            )
        }

        await store.send(.startStopBroadcastButtonTapped("stream-key")) {
            $0.isBroadcasting = false
        }
        await store.finish()

        #expect(await probe.stopBroadcastCount() == 1)
    }

    @Test
    @MainActor
    func broadcastStoppedClearsReducerState() async {
        let store = TestStore(
            initialState: BroadcastFeature.State(configuration: .init(isBroadcasting: true))
        ) {
            BroadcastFeature()
        }

        await store.send(.broadcastStopped) {
            $0.isBroadcasting = false
        }
    }
}
