//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AudioVideoKit
import ComposableArchitecture

@Reducer
struct CaptureFeature {

    @ObservableState
    struct State: Equatable {
        var cameraIsAuthorized = false
        var isCaptureSessionRunning = false
        var availableCameras: [CaptureDevice] = []
        var selectedCamera: CaptureDevice?
        var availableMicrophones: [CaptureDevice] = []
        var selectedMicrophone: CaptureDevice?

        init(configuration: BroadcastConfiguration = .init()) {
            self.cameraIsAuthorized = configuration.cameraIsAuthorized
            self.selectedCamera = configuration.selectedCamera
            self.selectedMicrophone = configuration.selectedMicrophone
        }
    }

    enum Action: Equatable {
        case bootstrap
        case bootstrapSucceeded
        case bootstrapFailed(String)
        case captureMicrophoneChanged(Bool)
        case defaultMicrophoneResolved(CaptureDevice?)
        case availableCamerasChanged([CaptureDevice])
        case selectedCameraChanged(CaptureDevice?)
        case availableMicrophonesChanged([CaptureDevice])
        case selectedMicrophoneChanged(CaptureDevice?)
        case cameraAuthorizationChanged(Bool)
        case startCaptureSession
        case stopCaptureSession
    }

    @Dependency(\.captureClient) private var captureClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .bootstrap:
                let selectedMicrophone = state.selectedMicrophone
                return .run { send in
                    do {
                        let isAuthorized = try await captureClient.bootstrap(
                            selectedMicrophone
                        )
                        await send(.cameraAuthorizationChanged(isAuthorized))
                        await send(.bootstrapSucceeded)
                    } catch {
                        await send(.bootstrapFailed(error.localizedDescription))
                    }
                }

            case .bootstrapSucceeded, .bootstrapFailed:
                return .none

            case let .captureMicrophoneChanged(isEnabled):
                guard isEnabled else {
                    state.selectedMicrophone = nil
                    return .run { _ in
                        await captureClient.setSelectedMicrophone(nil)
                    }
                }

                guard let selectedMicrophone = state.selectedMicrophone else {
                    return .run { send in
                        let defaultMicrophone = await captureClient.defaultMicrophone()
                        await send(.defaultMicrophoneResolved(defaultMicrophone))
                    }
                }

                return .run { _ in
                    await captureClient.setSelectedMicrophone(selectedMicrophone)
                }

            case let .defaultMicrophoneResolved(microphone):
                state.selectedMicrophone = microphone
                return .run { _ in
                    await captureClient.setSelectedMicrophone(microphone)
                }

            case let .availableCamerasChanged(cameras):
                state.availableCameras = cameras
                return .none

            case let .selectedCameraChanged(camera):
                state.selectedCamera = camera

                if camera == nil {
                    state.isCaptureSessionRunning = false
                    return .run { _ in
                        await captureClient.setSelectedCamera(nil)
                        await captureClient.stopCaptureSession()
                    }
                }

                return .run { _ in
                    await captureClient.setSelectedCamera(camera)
                }

            case let .availableMicrophonesChanged(microphones):
                state.availableMicrophones = microphones
                return .none

            case let .selectedMicrophoneChanged(microphone):
                state.selectedMicrophone = microphone
                return .run { _ in
                    await captureClient.setSelectedMicrophone(microphone)
                }

            case let .cameraAuthorizationChanged(isAuthorized):
                state.cameraIsAuthorized = isAuthorized
                if !isAuthorized {
                    state.isCaptureSessionRunning = false
                }
                return .none

            case .startCaptureSession:
                guard !state.isCaptureSessionRunning, state.selectedCamera != nil else {
                    return .none
                }

                state.isCaptureSessionRunning = true
                return .run { _ in
                    await captureClient.startCaptureSession()
                }

            case .stopCaptureSession:
                guard state.isCaptureSessionRunning else {
                    return .none
                }

                state.isCaptureSessionRunning = false
                return .run { _ in
                    await captureClient.stopCaptureSession()
                }
            }
        }
    }
}
