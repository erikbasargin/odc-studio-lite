import ComposableArchitecture
@testable import ODCLite
import Testing

@Suite
struct AppFeatureTests {

    @Test
    @MainActor
    func taskStartsBroadcastFlow() async {
        let initialSnapshot = BroadcastStateSnapshot(
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
                    initialSnapshot
                }
            )
        }

        await store.send(.task)
        await store.receive(.broadcast(.task))
        await store.receive(.broadcast(.stateDidChange(initialSnapshot))) {
            $0.broadcast = BroadcastFeature.State(snapshot: initialSnapshot)
            $0.settings = SettingsFeature.State()
        }

        #expect(await probe.bootstrapCount() == 1)
    }
}
