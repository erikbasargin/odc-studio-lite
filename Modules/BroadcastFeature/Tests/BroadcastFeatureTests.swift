import ComposableArchitecture
import Testing

@testable import BroadcastFeature

@Suite
struct BroadcastFeatureTests {
    
    @Test
    @MainActor
    func taskConfiguresBroadcastBuilder() async {
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        }
        
        await store.send(.bootstrap)
        await store.finish()
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
    func startBroadcastUsesExplicitPrimaryStreamKey() async {
        let probe = BroadcastFeatureProbe()
        let session = BroadcastSession()
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastSessionBuilder = .init(
                makeBroadcastSession: { primaryStreamKey, _ in
                    await probe.recordStartBroadcast(primaryStreamKey: primaryStreamKey)
                    return session
                }
            )
        }
        
        await store.send(.startBroadcast("stream-key"))
        await store.receive(.broadcastSessionIsReady(session)) {
            $0.broadcastSession = session
        }
        
        #expect(await probe.startBroadcastValues() == ["stream-key"])
    }
    
    @Test
    @MainActor
    func stopBroadcastWritesThroughDependency() async {
        let session = BroadcastSession()
        let store = TestStore(
            initialState: {
                BroadcastFeature.State(
                    isBroadcasting: true,
                    broadcastSession: session
                )
            }()
        ) {
            BroadcastFeature()
        }
        
        await store.send(.stopBroadcast) {
            $0.broadcastSession = nil
            $0.isBroadcasting = false
        }
        await store.finish()
    }
}

actor BroadcastFeatureProbe {
    private var startBroadcastRequests: [String] = []
    
    func recordStartBroadcast(primaryStreamKey: String) {
        startBroadcastRequests.append(primaryStreamKey)
    }
    
    func startBroadcastValues() -> [String] {
        startBroadcastRequests
    }
}
