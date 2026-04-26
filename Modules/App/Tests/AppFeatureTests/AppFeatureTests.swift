import ComposableArchitecture
import Foundation
import Testing

@testable import ODCLite

@Suite
struct AppFeatureTests {
    
    @Test
    @MainActor
    func taskStartsBroadcastFlow() async {
        let probe = AppClientProbe()
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.captureClient = .mock(
                bootstrap: {
                    await probe.recordBootstrap()
                    return true
                }
            )
        }
        
        await store.send(.bootstrap) {
            $0.bootstrapState = .inProgress
        }
        await store.receive(.settings(.bootstrap))
        await store.receive(.broadcast(.bootstrap))
        await store.receive(.capture(.bootstrap))
        await store.receive(.capture(.cameraAuthorizationChanged(true))) {
            $0.capture.cameraIsAuthorized = true
        }
        await store.receive(.capture(.bootstrapSucceeded)) {
            $0.bootstrapState = .finished
        }
        
        #expect(await probe.bootstrapCount() == 1)
    }
    
    @Test
    @MainActor
    func bootstrapFailureIsModeledInAppState() async {
        let bootstrapError = NSError(
            domain: "AppFeatureTests", code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "Bootstrap failed"
            ])
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.captureClient = .mock(
                bootstrap: {
                    throw bootstrapError
                }
            )
        }
        store.exhaustivity = .off
        
        await store.send(.bootstrap) {
            $0.bootstrapState = .inProgress
        }
        await store.receive(.settings(.bootstrap))
        await store.receive(.broadcast(.bootstrap))
        await store.receive(.capture(.bootstrap))
        await store.receive(.capture(.bootstrapFailed("Bootstrap failed"))) {
            $0.bootstrapState = .failed("Bootstrap failed")
        }
    }
    
    @Test
    @MainActor
    func startBroadcastUsesSettingsOwnedPrimaryStreamKey() async {
        let probe = AppClientProbe()
        let session = BroadcastSession()
        let store = TestStore(
            initialState: AppFeature.State(
                configuration: .init(primaryStreamKey: "stream-key")
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.captureClient = .mock(
                startBroadcast: { attachedSession in
                    await probe.recordAttachedBroadcastSession(attachedSession)
                }
            )
            $0.broadcastSessionBuilder = .init(
                makeBroadcastSession: { primaryStreamKey, _ in
                    await probe.recordStartBroadcast(primaryStreamKey: primaryStreamKey)
                    return session
                }
            )
        }
        
        await store.send(.startBroadcast)
        await store.receive(.broadcast(.startBroadcast("stream-key")))
        await store.receive(.broadcast(.broadcastSessionIsReady(session))) {
            $0.broadcast.broadcastSession = session
        }
        await store.receive(.broadcast(.initiateBroadcast)) {
            $0.broadcast.isBroadcasting = true
        }
        
        #expect(await probe.startBroadcastValues() == ["stream-key"])
        #expect(await probe.attachedBroadcastSessionCount() == 1)
    }
}
