import ComposableArchitecture
@testable import ODCLite
import Testing

@Suite
struct BroadcastFeatureTests {

    @Test
    @MainActor
    func taskConfiguresBroadcastBuilder() async {
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        }

        await store.send(.task)
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
        let probe = AppClientProbe()
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
                var state = BroadcastFeature.State(configuration: .init(isBroadcasting: true))
                state.broadcastSession = session
                return state
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
