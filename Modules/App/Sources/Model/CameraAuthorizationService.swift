//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

@preconcurrency import AVFoundation
import ComposableArchitecture

struct CameraAuthorizationService: Sendable {
    var authorize: @Sendable () async -> Bool
}

extension CameraAuthorizationService: DependencyKey {
    static let liveValue = Self(
        authorize: {
            let status = AVCaptureDevice.authorizationStatus(for: .video)

            switch status {
            case .notDetermined:
                return await AVCaptureDevice.requestAccess(for: .video)
            case .restricted, .denied:
                return false
            case .authorized:
                return true
            @unknown default:
                return false
            }
        }
    )

    static let testValue = Self(authorize: { false })
}

extension DependencyValues {
    var cameraAuthorizationService: CameraAuthorizationService {
        get { self[CameraAuthorizationService.self] }
        set { self[CameraAuthorizationService.self] = newValue }
    }
}
