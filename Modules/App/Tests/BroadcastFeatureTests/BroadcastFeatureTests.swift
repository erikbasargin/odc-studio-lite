import ComposableArchitecture
@testable import ODCLite
import Testing

@Suite
struct BroadcastFeatureTests {

    @Test
    @MainActor
    func taskObservesSnapshotUpdates() async {
        let initialSnapshot = BroadcastStateSnapshot(
            bandwidthTestEnabled: false,
            primaryStreamKey: "initial-key",
            isBroadcasting: false
        )
        let updatedSnapshot = BroadcastStateSnapshot(
            bandwidthTestEnabled: true,
            primaryStreamKey: "updated-key",
            isBroadcasting: true
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
        await store.receive(.stateDidChange(initialSnapshot)) {
            $0 = BroadcastFeature.State(snapshot: initialSnapshot)
        }

        continuation.yield(updatedSnapshot)

        await store.receive(.stateDidChange(updatedSnapshot)) {
            $0 = BroadcastFeature.State(snapshot: updatedSnapshot)
        }

        continuation.finish()
        await store.finish()

        #expect(await probe.bootstrapCount() == 1)
    }

    @Test
    @MainActor
    func primaryStreamKeyWritesThroughDependency() async {
        let probe = BroadcastClientProbe()
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                setPrimaryStreamKey: { key in
                    await probe.recordPrimaryStreamKey(key)
                }
            )
        }

        await store.send(.primaryStreamKeyChanged("abc123")) {
            $0.primaryStreamKey = "abc123"
        }
        await store.finish()

        #expect(await probe.primaryStreamKeys() == ["abc123"])
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
