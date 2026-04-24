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
        var capture: CaptureFeature.State
        var broadcast: BroadcastFeature.State
        var settings: SettingsFeature.State

        init(configuration: BroadcastConfiguration = .init()) {
            self.capture = CaptureFeature.State(configuration: configuration)
            self.broadcast = BroadcastFeature.State(configuration: configuration)
            self.settings = SettingsFeature.State(primaryStreamKey: configuration.primaryStreamKey)
        }
    }

    enum Action: Equatable {
        case task
        case retryButtonTapped
        case microphoneCaptureRequested(Bool)
        case startBroadcast
        case stopBroadcast
        case bootstrapSucceeded
        case bootstrapFailed(String)
        case capture(CaptureFeature.Action)
        case broadcast(BroadcastFeature.Action)
        case settings(SettingsFeature.Action)
    }

    @Dependency(\.captureClient) private var captureClient

    var body: some ReducerOf<Self> {
        Scope(state: \.capture, action: \.capture) {
            CaptureFeature()
        }

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
                let selectedMicrophone = state.capture.selectedMicrophone
                return .run { send in
                    do {
                        let isAuthorized = try await captureClient.bootstrap(
                            selectedMicrophone
                        )
                        await send(.capture(.cameraAuthorizationChanged(isAuthorized)))
                        await send(.bootstrapSucceeded)
                    } catch {
                        await send(.bootstrapFailed(error.localizedDescription))
                    }
                }

            case .retryButtonTapped:
                state.bootstrapState = .idle
                return .send(.task)

            case let .microphoneCaptureRequested(isEnabled):
                return .send(.capture(.captureMicrophoneChanged(isEnabled)))

            case .startBroadcast:
                return .send(
                    .broadcast(
                        .startBroadcast(state.settings.primaryStreamKey)
                    )
                )

            case .stopBroadcast:
                return .send(.broadcast(.stopBroadcast))

            case .bootstrapSucceeded:
                state.bootstrapState = .finished
                return .none

            case let .bootstrapFailed(message):
                state.bootstrapState = .failed(message)
                return .none

            case .capture, .broadcast, .settings:
                return .none
            }
        }
    }
}
