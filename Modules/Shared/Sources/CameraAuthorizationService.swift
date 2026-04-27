//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AVFoundation
import ComposableArchitecture

public struct CameraAuthorizationService: Sendable {
    public var authorize: @Sendable () async -> Bool
    
    public init(authorize: @escaping @Sendable () async -> Bool) {
        self.authorize = authorize
    }
}

extension CameraAuthorizationService: DependencyKey {
    public static let liveValue = Self(
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
    
    public static let testValue = Self(authorize: { false })
}

public extension DependencyValues {
    var cameraAuthorizationService: CameraAuthorizationService {
        get { self[CameraAuthorizationService.self] }
        set { self[CameraAuthorizationService.self] = newValue }
    }
}
