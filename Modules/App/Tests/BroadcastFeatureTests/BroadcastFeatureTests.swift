import ComposableArchitecture
@testable import ODCLite
import Testing

@Suite
struct BroadcastFeatureTests {

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
        let store = TestStore(initialState: BroadcastFeature.State()) {
            BroadcastFeature()
        } withDependencies: {
            $0.broadcastClient = .mock(
                startBroadcast: { primaryStreamKey, _ in
                    await probe.recordStartBroadcast(primaryStreamKey: primaryStreamKey)
                }
            )
        }

        await store.send(.startBroadcast("stream-key")) {
            $0.isBroadcasting = true
        }
        await store.finish()

        let requests = await probe.startBroadcastValues()
        #expect(requests == ["stream-key"])
    }

    @Test
    @MainActor
    func stopBroadcastWritesThroughDependency() async {
        let probe = AppClientProbe()
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

        await store.send(.stopBroadcast) {
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
