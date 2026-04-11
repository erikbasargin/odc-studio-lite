//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import Foundation
import os

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastFeature")

@Reducer
struct BroadcastFeature {

    @ObservableState
    struct State: Equatable {
        var bandwidthTestEnabled = false
        var primaryStreamKey = ""
        var isBroadcasting = false

        init(snapshot: BroadcastStateSnapshot = .init()) {
            self.bandwidthTestEnabled = snapshot.bandwidthTestEnabled
            self.primaryStreamKey = snapshot.primaryStreamKey
            self.isBroadcasting = snapshot.isBroadcasting
        }
    }

    enum Action: Equatable {
        case task
        case primaryStreamKeyChanged(String)
        case bandwidthTestEnabledChanged(Bool)
        case startStopBroadcastButtonTapped
        case stateDidChange(BroadcastStateSnapshot)
        case bootstrapFailed(String)
    }

    @Dependency(\.broadcastClient) private var broadcastClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    .run { send in
                        let initialSnapshot = await broadcastClient.snapshot()
                        await send(.stateDidChange(initialSnapshot))

                        let updates = await broadcastClient.updates()
                        for await snapshot in updates {
                            await send(.stateDidChange(snapshot))
                        }
                    },
                    .run { send in
                        do {
                            try await broadcastClient.bootstrap()
                        } catch {
                            log.error("Failed to bootstrap broadcast flow: \(error.localizedDescription)")
                            await send(.bootstrapFailed(error.localizedDescription))
                        }
                    }
                )

            case let .primaryStreamKeyChanged(primaryStreamKey):
                state.primaryStreamKey = primaryStreamKey
                return .run { _ in
                    await broadcastClient.setPrimaryStreamKey(primaryStreamKey)
                }

            case let .bandwidthTestEnabledChanged(bandwidthTestEnabled):
                state.bandwidthTestEnabled = bandwidthTestEnabled
                return .run { _ in
                    await broadcastClient.setBandwidthTestEnabled(bandwidthTestEnabled)
                }

            case .startStopBroadcastButtonTapped:
                return .run { _ in
                    await broadcastClient.toggleBroadcast()
                }

            case let .stateDidChange(snapshot):
                state = State(snapshot: snapshot)
                return .none

            case .bootstrapFailed:
                return .none
            }
        }
    }
}
