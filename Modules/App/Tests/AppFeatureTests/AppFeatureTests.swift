import ComposableArchitecture
@testable import ODCLite
import Foundation
import Testing

@Suite
struct AppFeatureTests {

    @Test
    @MainActor
    func taskStartsBroadcastFlow() async {
        let probe = BroadcastClientProbe()
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                bootstrap: { selectedMicrophone in
                    await probe.recordBootstrap(selectedMicrophone: selectedMicrophone)
                    return true
                }
            )
        }

        await store.send(.task) {
            $0.bootstrapState = .inProgress
        }
        await store.receive(.broadcast(.task))
        await store.receive(.broadcast(.cameraAuthorizationChanged(true))) {
            $0.broadcast.cameraIsAuthorized = true
        }
        await store.receive(.bootstrapSucceeded) {
            $0.bootstrapState = .finished
        }

        #expect(await probe.bootstrapCount() == 1)
        #expect(await probe.bootstrapSelectedMicrophones() == [nil])
    }

    @Test
    @MainActor
    func bootstrapFailureIsModeledInAppState() async {
        let bootstrapError = NSError(domain: "AppFeatureTests", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Bootstrap failed"
        ])
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                bootstrap: { _ in
                    throw bootstrapError
                }
            )
        }
        store.exhaustivity = .off

        await store.send(.task) {
            $0.bootstrapState = .inProgress
        }
        await store.receive(.broadcast(.task))
        await store.receive(.bootstrapFailed("Bootstrap failed")) {
            $0.bootstrapState = .failed("Bootstrap failed")
        }
    }

    @Test
    @MainActor
    func microphoneCaptureRequestRoutesThroughBroadcastFeature() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.microphoneCaptureRequested(true))
        await store.receive(.broadcast(.captureMicrophoneChanged(true)))
    }

    @Test
    @MainActor
    func startBroadcastUsesSettingsOwnedPrimaryStreamKey() async {
        let store = TestStore(
            initialState: AppFeature.State(
                configuration: .init(primaryStreamKey: "stream-key")
            )
        ) {
            AppFeature()
        }

        await store.send(.startBroadcast)
        await store.receive(.broadcast(.startBroadcast("stream-key")))
    }
}
