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

        init(snapshot: BroadcastStateSnapshot = .init()) {
            self.bandwidthTestEnabled = snapshot.bandwidthTestEnabled
            self.isBroadcasting = snapshot.isBroadcasting
            self.cameraIsAuthorized = snapshot.cameraIsAuthorized
            self.selectedCamera = snapshot.selectedCamera
            self.selectedMicrophone = snapshot.selectedMicrophone
        }
    }

    enum Action: Equatable {
        case task
        case bandwidthTestEnabledChanged(Bool)
        case availableCamerasChanged([CaptureDevice])
        case selectedCameraChanged(CaptureDevice?)
        case availableMicrophonesChanged([CaptureDevice])
        case selectedMicrophoneChanged(CaptureDevice?)
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

            case let .bandwidthTestEnabledChanged(bandwidthTestEnabled):
                state.bandwidthTestEnabled = bandwidthTestEnabled
                return .run { _ in
                    await broadcastClient.setBandwidthTestEnabled(bandwidthTestEnabled)
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

            case let .stateDidChange(snapshot):
                state.bandwidthTestEnabled = snapshot.bandwidthTestEnabled
                state.isBroadcasting = snapshot.isBroadcasting
                state.cameraIsAuthorized = snapshot.cameraIsAuthorized
                state.selectedCamera = snapshot.selectedCamera
                state.selectedMicrophone = snapshot.selectedMicrophone
                return .none

            case .bootstrapFailed:
                return .none
            }
        }
    }
}
