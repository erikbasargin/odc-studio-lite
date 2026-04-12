//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture

@Reducer
struct AppFeature {

    @ObservableState
    struct State: Equatable {
        var broadcast: BroadcastFeature.State
        var settings: SettingsFeature.State

        init(snapshot: BroadcastStateSnapshot = .init()) {
            self.broadcast = BroadcastFeature.State(snapshot: snapshot)
            self.settings = SettingsFeature.State()
        }
    }

    enum Action: Equatable {
        case task
        case broadcast(BroadcastFeature.Action)
        case settings(SettingsFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.broadcast, action: \.broadcast) {
            BroadcastFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                return .send(.broadcast(.task))

            case .broadcast, .settings:
                return .none
            }
        }
    }
}
