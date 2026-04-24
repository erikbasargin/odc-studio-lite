//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ComposableArchitecture
import OSLog
import ScreenCaptureKit

import AudioVideoKit
import RTMPHaishinKit

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BroadcastClient")

struct BroadcastClient: Sendable {
    var bootstrap: @Sendable () async throws -> Void
    var snapshot: @Sendable () async -> BroadcastConfiguration
    var updates: @Sendable () async -> AsyncStream<BroadcastConfiguration>
    var setPrimaryStreamKey: @Sendable (String) async -> Void
    var setBandwidthTestEnabled: @Sendable (Bool) async -> Void
    var setCaptureMicrophone: @Sendable (Bool) async -> Void
    var setSelectedCamera: @Sendable (CaptureDevice?) async -> Void
    var setSelectedMicrophone: @Sendable (CaptureDevice?) async -> Void
    var toggleBroadcast: @Sendable () async -> Void
}

extension BroadcastClient: DependencyKey {
    static let liveValue = Self.unimplemented
    static let testValue = Self.unimplemented

    private static let unimplemented = Self(
        bootstrap: {},
        snapshot: { .init() },
        updates: { AsyncStream { _ in } },
        setPrimaryStreamKey: { _ in },
        setBandwidthTestEnabled: { _ in },
        setCaptureMicrophone: { _ in },
        setSelectedCamera: { _ in },
        setSelectedMicrophone: { _ in },
        toggleBroadcast: {}
    )
}

extension DependencyValues {
    var broadcastClient: BroadcastClient {
        get { self[BroadcastClient.self] }
        set { self[BroadcastClient.self] = newValue }
    }
}

extension BroadcastClient {
    @MainActor
    static func live(
        _ broadcastManager: BroadcastManager,
        cameraAuthorizationService: CameraAuthorizationService = .liveValue,
        broadcastSessionBuilder: BroadcastSessionBuilder = .init()
    ) -> Self {
        let runtime = LiveBroadcastRuntime(
            broadcastManager: broadcastManager,
            cameraAuthorizationService: cameraAuthorizationService,
            broadcastSessionBuilder: broadcastSessionBuilder
        )

        return Self(
            bootstrap: {
                try await runtime.bootstrap()
            },
            snapshot: {
                await runtime.snapshot()
            },
            updates: {
                await runtime.updates()
            },
            setPrimaryStreamKey: { primaryStreamKey in
                await runtime.setPrimaryStreamKey(primaryStreamKey)
            },
            setBandwidthTestEnabled: { bandwidthTestEnabled in
                await runtime.setBandwidthTestEnabled(bandwidthTestEnabled)
            },
            setCaptureMicrophone: { isEnabled in
                await runtime.setCaptureMicrophone(isEnabled)
            },
            setSelectedCamera: { camera in
                await runtime.setSelectedCamera(camera)
            },
            setSelectedMicrophone: { microphone in
                await runtime.setSelectedMicrophone(microphone)
            },
            toggleBroadcast: {
                await runtime.toggleBroadcast()
            }
        )
    }
}

@MainActor
private final class LiveBroadcastRuntime {

    private let broadcastManager: BroadcastManager
    private let cameraAuthorizationService: CameraAuthorizationService
    private let broadcastSessionBuilder: BroadcastSessionBuilder
    private let captureSystem = CaptureSystem()
    private let mediaMixerController = MediaMixerController()
    private var broadcastSession: BroadcastSession?

    init(
        broadcastManager: BroadcastManager,
        cameraAuthorizationService: CameraAuthorizationService,
        broadcastSessionBuilder: BroadcastSessionBuilder
    ) {
        self.broadcastManager = broadcastManager
        self.cameraAuthorizationService = cameraAuthorizationService
        self.broadcastSessionBuilder = broadcastSessionBuilder
    }

    func bootstrap() async throws {
        try await mediaMixerController.bootstrapCapture(
            using: captureSystem,
            configuration: broadcastManager.currentCaptureConfiguration(),
            contentFilter: broadcastManager.currentStreamContentFilter()
        )
        await BroadcastSessionBuilder.configure()

        var initialConfiguration = SCContentSharingPickerConfiguration()
        initialConfiguration.allowedPickerModes = [.singleDisplay]
        initialConfiguration.allowsChangingSelectedContent = true
        SCContentSharingPicker.shared.configuration = initialConfiguration
        SCContentSharingPicker.shared.isActive = true

        let isAuthorized = await cameraAuthorizationService.authorize()
        broadcastManager.updateCameraAuthorization(isAuthorized)
    }

    func snapshot() -> BroadcastConfiguration {
        broadcastManager.broadcastConfiguration()
    }

    func updates() -> AsyncStream<BroadcastConfiguration> {
        broadcastManager.broadcastConfigurationUpdates()
    }

    func setPrimaryStreamKey(_ primaryStreamKey: String) {
        broadcastManager.updatePrimaryStreamKey(primaryStreamKey)
    }

    func setBandwidthTestEnabled(_ bandwidthTestEnabled: Bool) {
        broadcastManager.updateBandwidthTestEnabled(bandwidthTestEnabled)
    }

    func setCaptureMicrophone(_ isEnabled: Bool) async {
        broadcastManager.updateCaptureMicrophone(isEnabled)
        await updateCaptureConfiguration()
    }

    func setSelectedCamera(_ camera: CaptureDevice?) async {
        broadcastManager.updateSelectedCamera(camera)
        await updateCaptureConfiguration()
    }

    func setSelectedMicrophone(_ microphone: CaptureDevice?) async {
        broadcastManager.updateSelectedMicrophone(microphone)
        await updateCaptureConfiguration()
    }

    func toggleBroadcast() async {
        let configuration = broadcastManager.broadcastConfiguration()

        if configuration.isBroadcasting {
            await stopBroadcast()
            return
        }

        do {
            let session = try await broadcastSessionBuilder.makeBroadcastSession(
                primaryStreamKey: configuration.primaryStreamKey
            )
            try await startBroadcast(session)
        } catch {
            log.error("Failed to create broadcast session: \(error.localizedDescription)")
        }
    }

    private func startBroadcast(_ session: BroadcastSession) async throws {
        await stopBroadcast()
        broadcastSession = session
        broadcastManager.updateIsBroadcasting(true)

        do {
            let stream = await session.stream()
            let frameRate = Float64(
                broadcastManager.currentCaptureConfiguration().minimumFrameInterval.timescale
            )

            try await mediaMixerController.startBroadcast(
                stream: stream,
                frameRate: frameRate
            )
            try await session.connect { [weak self] in
                Task { @MainActor [weak self] in
                    await self?.stopBroadcast()
                }
            }
        } catch RTMPConnection.Error.requestFailed {
            log.error("RTMP connection request failed")
            await stopBroadcast()
        } catch RTMPStream.Error.requestFailed {
            log.error("RTMP stream request failed")
            await stopBroadcast()
        } catch {
            log.error("\(error.localizedDescription)")
            await stopBroadcast()
        }
    }

    private func stopBroadcast() async {
        guard broadcastManager.broadcastConfiguration().isBroadcasting || broadcastSession != nil else {
            return
        }

        broadcastManager.updateIsBroadcasting(false)
        await mediaMixerController.stopBroadcast()

        do {
            try await broadcastSession?.close()
            broadcastSession = nil
        } catch {
            log.error("Error closing session: \(error.localizedDescription)")
            broadcastSession = nil
        }
    }

    private func updateCaptureConfiguration() async {
        do {
            try await mediaMixerController.updateCaptureConfiguration(
                broadcastManager.currentCaptureConfiguration(),
                using: captureSystem
            )
        } catch {
            log.error("Failed to update stream configuration: \(error.localizedDescription)")
        }
    }
}
