import AudioVideoKit
import ComposableArchitecture
@testable import ODCLite
import Testing

@Suite
struct CaptureFeatureTests {

    @Test
    @MainActor
    func bootstrapWritesThroughDependency() async {
        let probe = AppClientProbe()
        let store = TestStore(initialState: CaptureFeature.State()) {
            CaptureFeature()
        } withDependencies: {
            $0.captureClient = .mock(
                bootstrap: { selectedMicrophone in
                    await probe.recordBootstrap(selectedMicrophone: selectedMicrophone)
                    return false
                }
            )
        }

        await store.send(.bootstrap)
        await store.receive(.cameraAuthorizationChanged(false))
        await store.receive(.bootstrapSucceeded)

        #expect(await probe.bootstrapCount() == 1)
        #expect(await probe.bootstrapSelectedMicrophones() == [nil])
    }

    @Test
    @MainActor
    func microphoneCaptureDisablesSelectedMicrophone() async {
        let probe = AppClientProbe()
        let microphone = CaptureDevice(id: "microphone-1", name: "MacBook Pro Microphone")
        let store = TestStore(initialState: CaptureFeature.State()) {
            CaptureFeature()
        } withDependencies: {
            $0.captureClient = .mock(
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
        let probe = AppClientProbe()
        let microphone = CaptureDevice(id: "microphone-1", name: "MacBook Pro Microphone")
        await probe.setDefaultMicrophone(microphone)
        let store = TestStore(initialState: CaptureFeature.State()) {
            CaptureFeature()
        } withDependencies: {
            $0.captureClient = .mock(
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
        let store = TestStore(initialState: CaptureFeature.State()) {
            CaptureFeature()
        }

        await store.send(.availableCamerasChanged(cameras)) {
            $0.availableCameras = cameras
        }
    }

    @Test
    @MainActor
    func availableMicrophonesAreReducerOwned() async {
        let microphones = [CaptureDevice(id: "microphone-1", name: "MacBook Pro Microphone")]
        let store = TestStore(initialState: CaptureFeature.State()) {
            CaptureFeature()
        }

        await store.send(.availableMicrophonesChanged(microphones)) {
            $0.availableMicrophones = microphones
        }
    }

    @Test
    @MainActor
    func selectedCameraWritesThroughDependency() async {
        let probe = AppClientProbe()
        let camera = CaptureDevice(id: "camera-1", name: "FaceTime HD Camera")
        let store = TestStore(initialState: CaptureFeature.State()) {
            CaptureFeature()
        } withDependencies: {
            $0.captureClient = .mock(
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
        let probe = AppClientProbe()
        let microphone = CaptureDevice(id: "microphone-1", name: "MacBook Pro Microphone")
        let store = TestStore(initialState: CaptureFeature.State()) {
            CaptureFeature()
        } withDependencies: {
            $0.captureClient = .mock(
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
    func startCaptureSessionWritesThroughDependency() async {
        let probe = AppClientProbe()
        let camera = CaptureDevice(id: "camera-1", name: "FaceTime HD Camera")
        let store = TestStore(
            initialState: CaptureFeature.State(
                configuration: .init(selectedCamera: camera)
            )
        ) {
            CaptureFeature()
        } withDependencies: {
            $0.captureClient = .mock(
                startCaptureSession: {
                    await probe.recordStartCaptureSession()
                }
            )
        }

        await store.send(.startCaptureSession) {
            $0.isCaptureSessionRunning = true
        }
        await store.finish()

        #expect(await probe.startCaptureSessionCount() == 1)
    }

    @Test
    @MainActor
    func stopCaptureSessionWritesThroughDependency() async {
        let probe = AppClientProbe()
        let camera = CaptureDevice(id: "camera-1", name: "FaceTime HD Camera")
        let store = TestStore(
            initialState: CaptureFeature.State(
                configuration: .init(selectedCamera: camera)
            )
        ) {
            CaptureFeature()
        } withDependencies: {
            $0.captureClient = .mock(
                stopCaptureSession: {
                    await probe.recordStopCaptureSession()
                }
            )
        }

        await store.send(.startCaptureSession) {
            $0.isCaptureSessionRunning = true
        }
        await store.send(.stopCaptureSession) {
            $0.isCaptureSessionRunning = false
        }
        await store.finish()

        #expect(await probe.stopCaptureSessionCount() == 1)
    }

    @Test
    @MainActor
    func clearingCameraStopsCaptureSession() async {
        let probe = AppClientProbe()
        let store = TestStore(
            initialState: CaptureFeature.State(
                configuration: .init(selectedCamera: CaptureDevice(id: "camera-1", name: "FaceTime HD Camera"))
            )
        ) {
            CaptureFeature()
        } withDependencies: {
            $0.captureClient = .mock(
                setSelectedCamera: { selectedCamera in
                    await probe.recordSelectedCamera(selectedCamera)
                },
                stopCaptureSession: {
                    await probe.recordStopCaptureSession()
                }
            )
        }

        await store.send(.startCaptureSession) {
            $0.isCaptureSessionRunning = true
        }
        await store.send(.selectedCameraChanged(nil)) {
            $0.selectedCamera = nil
            $0.isCaptureSessionRunning = false
        }
        await store.finish()

        #expect(await probe.selectedCameraValues() == [nil])
        #expect(await probe.stopCaptureSessionCount() == 1)
    }
}
