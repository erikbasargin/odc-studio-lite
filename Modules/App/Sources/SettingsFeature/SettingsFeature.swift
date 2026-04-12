//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture

@Reducer
struct SettingsFeature {

    @ObservableState
    struct State: Equatable {
        var primaryStreamKey = ""
    }

    enum Action: Equatable {
        case primaryStreamKeyChanged(String)
    }

    @Dependency(\.broadcastClient) private var broadcastClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .primaryStreamKeyChanged(primaryStreamKey):
                state.primaryStreamKey = primaryStreamKey
                return .run { _ in
                    await broadcastClient.setPrimaryStreamKey(primaryStreamKey)
                }
            }
        }
    }
}
