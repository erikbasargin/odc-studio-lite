//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
@Reducer
struct BroadcastFeature {

    @ObservableState
    struct State: Equatable {
        var bandwidthTestEnabled = false
        var isBroadcasting = false

        init(configuration: BroadcastConfiguration = .init()) {
            self.bandwidthTestEnabled = configuration.bandwidthTestEnabled
            self.isBroadcasting = configuration.isBroadcasting
        }
    }

    enum Action: Equatable {
        case bandwidthTestEnabledChanged(Bool)
        case startBroadcast(String)
        case stopBroadcast
        case broadcastStopped
    }

    @Dependency(\.broadcastClient) private var broadcastClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .bandwidthTestEnabledChanged(bandwidthTestEnabled):
                state.bandwidthTestEnabled = bandwidthTestEnabled
                return .none

            case let .startBroadcast(primaryStreamKey):
                state.isBroadcasting = true
                return .run { send in
                    do {
                        try await broadcastClient.startBroadcast(
                            primaryStreamKey
                        ) {
                            await send(.broadcastStopped)
                        }
                    } catch {
                        await send(.broadcastStopped)
                    }
                }

            case .stopBroadcast:
                state.isBroadcasting = false
                return .run { _ in
                    await broadcastClient.stopBroadcast()
                }

            case .broadcastStopped:
                state.isBroadcasting = false
                return .none
            }
        }
    }
}
