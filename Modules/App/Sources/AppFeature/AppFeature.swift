//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture

@Reducer
struct AppFeature {

    enum BootstrapState: Equatable {
        case idle
        case inProgress
        case finished
        case failed(String)
    }

    @ObservableState
    struct State: Equatable {
        var bootstrapState: BootstrapState = .idle
        var broadcast: BroadcastFeature.State
        var settings: SettingsFeature.State

        init(snapshot: BroadcastStateSnapshot = .init()) {
            self.broadcast = BroadcastFeature.State(snapshot: snapshot)
            self.settings = SettingsFeature.State(primaryStreamKey: snapshot.primaryStreamKey)
        }
    }

    enum Action: Equatable {
        case task
        case retryButtonTapped
        case microphoneCaptureRequested(Bool)
        case bootstrapSucceeded
        case bootstrapFailed(String)
        case broadcast(BroadcastFeature.Action)
        case settings(SettingsFeature.Action)
    }

    @Dependency(\.broadcastClient) private var broadcastClient

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
                guard case .idle = state.bootstrapState else {
                    return .none
                }

                state.bootstrapState = .inProgress
                return .merge(
                    .send(.broadcast(.task)),
                    .run { send in
                        do {
                            try await broadcastClient.bootstrap()
                            await send(.bootstrapSucceeded)
                        } catch {
                            await send(.bootstrapFailed(error.localizedDescription))
                        }
                    }
                )

            case .retryButtonTapped:
                state.bootstrapState = .idle
                return .send(.task)

            case let .microphoneCaptureRequested(isEnabled):
                return .send(.broadcast(.captureMicrophoneChanged(isEnabled)))

            case .bootstrapSucceeded:
                state.bootstrapState = .finished
                return .none

            case let .bootstrapFailed(message):
                state.bootstrapState = .failed(message)
                return .none

            case .broadcast, .settings:
                return .none
            }
        }
    }
}
