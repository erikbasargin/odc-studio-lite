import ComposableArchitecture
@testable import ODCLite
import Foundation
import Testing

@Suite
struct AppFeatureTests {

    @Test
    @MainActor
    func taskStartsBroadcastFlow() async {
        let initialConfiguration = BroadcastConfiguration(
            bandwidthTestEnabled: true,
            primaryStreamKey: "stream-key",
            isBroadcasting: false
        )
        let probe = BroadcastClientProbe()
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                bootstrap: {
                    await probe.recordBootstrap()
                },
                snapshot: {
                    initialConfiguration
                }
            )
        }

        await store.send(.task) {
            $0.bootstrapState = .inProgress
        }
        await store.receive(.broadcast(.task))
        await store.receive(.bootstrapSucceeded) {
            $0.bootstrapState = .finished
        }
        await store.receive(.broadcast(.stateDidChange(initialConfiguration))) {
            $0.broadcast = BroadcastFeature.State(configuration: initialConfiguration)
            $0.settings = SettingsFeature.State()
        }

        #expect(await probe.bootstrapCount() == 1)
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
                bootstrap: {
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
}
