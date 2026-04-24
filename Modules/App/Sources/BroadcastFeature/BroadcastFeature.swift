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
        var broadcastSession: BroadcastSession?

        init(configuration: BroadcastConfiguration = .init()) {
            self.bandwidthTestEnabled = configuration.bandwidthTestEnabled
            self.isBroadcasting = configuration.isBroadcasting
        }
    }

    enum Action: Equatable {
        case task
        case bandwidthTestEnabledChanged(Bool)
        case startBroadcast(String)
        case initiateBroadcast
        case stopBroadcast
        case broadcastSessionIsReady(BroadcastSession)
        case broadcastSessionDisconnected
        case broadcastStopped
    }
    
    @Dependency(\.broadcastSessionBuilder) var broadcastSessionBuilder

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { _ in
                    await BroadcastSessionBuilder.configure()
                }

            case let .bandwidthTestEnabledChanged(bandwidthTestEnabled):
                state.bandwidthTestEnabled = bandwidthTestEnabled
                return .none

            case let .startBroadcast(primaryStreamKey):
                return .run { send in
                    do {
                        let session = try await broadcastSessionBuilder.makeBroadcastSession(primaryStreamKey, .default)
                        await send(.broadcastSessionIsReady(session))
                    } catch {
                        await send(.broadcastStopped)
                    }
                }

            case .stopBroadcast:
                let session = state.broadcastSession
                state.broadcastSession = nil
                state.isBroadcasting = false
                return .run { _ in
                    try await session?.close()
                }

            case let .broadcastSessionIsReady(session):
                state.broadcastSession = session
                return .none

            case .initiateBroadcast:
                guard let session = state.broadcastSession else {
                    return .none
                }

                state.isBroadcasting = true
                return .run { send in
                    do {
                        try await session.connect {
                            Task {
                                await send(.broadcastSessionDisconnected)
                            }
                        }
                    } catch {
                        await send(.broadcastSessionDisconnected)
                    }
                }

            case .broadcastSessionDisconnected:
                let session = state.broadcastSession
                state.broadcastSession = nil
                state.isBroadcasting = false
                return .run { _ in
                    try await session?.close()
                }

            case .broadcastStopped:
                state.broadcastSession = nil
                state.isBroadcasting = false
                return .none
            }
        }
    }
}
