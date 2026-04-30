//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import Shared

@Reducer
public struct BroadcastFeature {
    
    @ObservableState
    public struct State: Equatable {
        public var bandwidthTestEnabled = false
        public var isBroadcasting = false
        public var broadcastSession: BroadcastSession?
        
        public init(
            bandwidthTestEnabled: Bool = false,
            isBroadcasting: Bool = false,
            broadcastSession: BroadcastSession? = nil
        ) {
            self.bandwidthTestEnabled = bandwidthTestEnabled
            self.isBroadcasting = isBroadcasting
            self.broadcastSession = broadcastSession
        }
        
        public init(configuration: BroadcastConfiguration = .init()) {
            self.bandwidthTestEnabled = configuration.bandwidthTestEnabled
            self.isBroadcasting = configuration.isBroadcasting
            self.broadcastSession = nil
        }
    }
    
    public enum Action: Equatable {
        case bootstrap
        case bandwidthTestEnabledChanged(Bool)
        case startBroadcast
        case initiateBroadcast
        case stopBroadcast
        case broadcastSessionIsReady(BroadcastSession)
        case broadcastSessionDisconnected
        case broadcastStopped
    }
    
    @Dependency(\.broadcastSessionBuilder) var broadcastSessionBuilder
    @Dependency(\.twitchPrimaryKeyStorage) var twitchPrimaryKeyStorage
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .bootstrap:
                return .run { _ in
                    await BroadcastSessionBuilder.configure()
                }

            case .bandwidthTestEnabledChanged(let bandwidthTestEnabled):
                state.bandwidthTestEnabled = bandwidthTestEnabled
                return .none

            case .startBroadcast:
                let broadcastSessionBuilder = broadcastSessionBuilder
                let twitchPrimaryKeyStorage = twitchPrimaryKeyStorage
                return .run { send in
                    do {
                        guard let primaryStreamKey = try twitchPrimaryKeyStorage.load() else {
                            await send(.broadcastStopped)
                            return
                        }
                        
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

            case .broadcastSessionIsReady(let session):
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
