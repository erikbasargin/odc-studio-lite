import ComposableArchitecture
@testable import ODCLite
import Testing

@Suite
struct SettingsFeatureTests {

    @Test
    @MainActor
    func primaryStreamKeyWritesThroughDependency() async {
        let probe = BroadcastClientProbe()
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
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
}
