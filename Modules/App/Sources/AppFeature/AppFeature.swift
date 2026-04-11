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

        init(snapshot: BroadcastStateSnapshot = .init()) {
            self.broadcast = BroadcastFeature.State(snapshot: snapshot)
        }
    }

    enum Action: Equatable {
        case task
        case broadcast(BroadcastFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.broadcast, action: \.broadcast) {
            BroadcastFeature()
        }

        Reduce { _, action in
            switch action {
            case .task:
                return .send(.broadcast(.task))
            case .broadcast:
                return .none
            }
        }
    }
}
