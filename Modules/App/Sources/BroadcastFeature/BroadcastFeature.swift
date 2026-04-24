//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture

import AudioVideoKit

@Reducer
struct BroadcastFeature {

    @ObservableState
    struct State: Equatable {
        var bandwidthTestEnabled = false
        var isBroadcasting = false
        var cameraIsAuthorized = false
        var availableCameras: [CaptureDevice] = []
        var selectedCamera: CaptureDevice?
        var availableMicrophones: [CaptureDevice] = []
        var selectedMicrophone: CaptureDevice?

        init(configuration: BroadcastConfiguration = .init()) {
            self.bandwidthTestEnabled = configuration.bandwidthTestEnabled
            self.isBroadcasting = configuration.isBroadcasting
            self.cameraIsAuthorized = configuration.cameraIsAuthorized
            self.selectedCamera = configuration.selectedCamera
            self.selectedMicrophone = configuration.selectedMicrophone
        }
    }

    enum Action: Equatable {
        case task
        case captureMicrophoneChanged(Bool)
        case defaultMicrophoneResolved(CaptureDevice?)
        case bandwidthTestEnabledChanged(Bool)
        case availableCamerasChanged([CaptureDevice])
        case selectedCameraChanged(CaptureDevice?)
        case availableMicrophonesChanged([CaptureDevice])
        case selectedMicrophoneChanged(CaptureDevice?)
        case cameraAuthorizationChanged(Bool)
        case startBroadcast(String)
        case stopBroadcast
        case broadcastStopped
    }

    @Dependency(\.broadcastClient) private var broadcastClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .none

            case let .bandwidthTestEnabledChanged(bandwidthTestEnabled):
                state.bandwidthTestEnabled = bandwidthTestEnabled
                return .none

            case let .captureMicrophoneChanged(isEnabled):
                guard isEnabled else {
                    state.selectedMicrophone = nil
                    return .run { _ in
                        await broadcastClient.setSelectedMicrophone(nil)
                    }
                }

                guard let selectedMicrophone = state.selectedMicrophone else {
                    return .run { send in
                        let defaultMicrophone = await broadcastClient.defaultMicrophone()
                        await send(.defaultMicrophoneResolved(defaultMicrophone))
                    }
                }

                return .run { _ in
                    await broadcastClient.setSelectedMicrophone(selectedMicrophone)
                }

            case let .defaultMicrophoneResolved(microphone):
                state.selectedMicrophone = microphone
                return .run { _ in
                    await broadcastClient.setSelectedMicrophone(microphone)
                }

            case let .availableCamerasChanged(cameras):
                state.availableCameras = cameras
                return .none

            case let .selectedCameraChanged(camera):
                state.selectedCamera = camera
                return .run { _ in
                    await broadcastClient.setSelectedCamera(camera)
                }

            case let .availableMicrophonesChanged(microphones):
                state.availableMicrophones = microphones
                return .none

            case let .selectedMicrophoneChanged(microphone):
                state.selectedMicrophone = microphone
                return .run { _ in
                    await broadcastClient.setSelectedMicrophone(microphone)
                }

            case let .cameraAuthorizationChanged(isAuthorized):
                state.cameraIsAuthorized = isAuthorized
                return .none

            case let .startBroadcast(primaryStreamKey):
                state.isBroadcasting = true
                let selectedMicrophone = state.selectedMicrophone
                return .run { send in
                    do {
                        try await broadcastClient.startBroadcast(
                            primaryStreamKey,
                            selectedMicrophone
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
