//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import Foundation
import os

import AudioVideoKit

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastFeature")

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
        case bandwidthTestEnabledChanged(Bool)
        case availableCamerasChanged([CaptureDevice])
        case selectedCameraChanged(CaptureDevice?)
        case availableMicrophonesChanged([CaptureDevice])
        case selectedMicrophoneChanged(CaptureDevice?)
        case startStopBroadcastButtonTapped
        case stateDidChange(BroadcastConfiguration)
        case bootstrapFailed(String)
    }

    @Dependency(\.broadcastClient) private var broadcastClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    let initialSnapshot = await broadcastClient.snapshot()
                    await send(.stateDidChange(initialSnapshot))

                    let updates = await broadcastClient.updates()
                    for await snapshot in updates {
                        await send(.stateDidChange(snapshot))
                    }
                }

            case let .bandwidthTestEnabledChanged(bandwidthTestEnabled):
                state.bandwidthTestEnabled = bandwidthTestEnabled
                return .run { _ in
                    await broadcastClient.setBandwidthTestEnabled(bandwidthTestEnabled)
                }

            case let .captureMicrophoneChanged(isEnabled):
                return .run { _ in
                    await broadcastClient.setCaptureMicrophone(isEnabled)
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

            case .startStopBroadcastButtonTapped:
                return .run { _ in
                    await broadcastClient.toggleBroadcast()
                }

            case let .stateDidChange(configuration):
                state.bandwidthTestEnabled = configuration.bandwidthTestEnabled
                state.isBroadcasting = configuration.isBroadcasting
                state.cameraIsAuthorized = configuration.cameraIsAuthorized
                state.selectedCamera = configuration.selectedCamera
                state.selectedMicrophone = configuration.selectedMicrophone
                return .none

            case let .bootstrapFailed(message):
                log.error("Failed to bootstrap broadcast flow: \(message)")
                return .none
            }
        }
    }
}
