import ComposableArchitecture
@testable import ODCLite
import Testing

@Suite
struct SettingsFeatureTests {

    @Test
    @MainActor
    func primaryStreamKeyIsReducerOwned() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.primaryStreamKeyChanged("abc123")) {
            $0.primaryStreamKey = "abc123"
        }
    }
}
