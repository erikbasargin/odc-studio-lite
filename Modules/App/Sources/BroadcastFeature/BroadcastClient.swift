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
    var bootstrap: @Sendable (CaptureDevice?) async throws -> Bool
    var defaultMicrophone: @Sendable () async -> CaptureDevice?
    var setSelectedCamera: @Sendable (CaptureDevice?) async -> Void
    var setSelectedMicrophone: @Sendable (CaptureDevice?) async -> Void
    var startBroadcast: @Sendable (
        String,
        CaptureDevice?,
        @escaping @Sendable () async -> Void
    ) async throws -> Void
    var stopBroadcast: @Sendable () async -> Void
}

extension BroadcastClient: DependencyKey {
    static let liveValue = Self.unimplemented
    static let testValue = Self.unimplemented

    private static let unimplemented = Self(
        bootstrap: { _ in false },
        defaultMicrophone: { nil },
        setSelectedCamera: { _ in },
        setSelectedMicrophone: { _ in },
        startBroadcast: { _, _, _ in },
        stopBroadcast: {}
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
            bootstrap: { selectedMicrophone in
                try await runtime.bootstrap(selectedMicrophone: selectedMicrophone)
            },
            defaultMicrophone: {
                await runtime.defaultMicrophone()
            },
            setSelectedCamera: { camera in
                await runtime.setSelectedCamera(camera)
            },
            setSelectedMicrophone: { microphone in
                await runtime.setSelectedMicrophone(microphone)
            },
            startBroadcast: { primaryStreamKey, selectedMicrophone, disconnected in
                try await runtime.startBroadcast(
                    primaryStreamKey: primaryStreamKey,
                    selectedMicrophone: selectedMicrophone,
                    disconnected: disconnected
                )
            },
            stopBroadcast: {
                await runtime.stopBroadcast()
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

    func bootstrap(selectedMicrophone: CaptureDevice?) async throws -> Bool {
        try await mediaMixerController.bootstrapCapture(
            using: captureSystem,
            configuration: broadcastManager.makeCaptureConfiguration(
                selectedMicrophone: selectedMicrophone
            ),
            contentFilter: broadcastManager.makeStreamContentFilter()
        )
        await BroadcastSessionBuilder.configure()

        var initialConfiguration = SCContentSharingPickerConfiguration()
        initialConfiguration.allowedPickerModes = [.singleDisplay]
        initialConfiguration.allowsChangingSelectedContent = true
        SCContentSharingPicker.shared.configuration = initialConfiguration
        SCContentSharingPicker.shared.isActive = true

        return await cameraAuthorizationService.authorize()
    }

    func defaultMicrophone() -> CaptureDevice? {
        broadcastManager.defaultMicrophoneDevice()
    }

    func setSelectedCamera(_ camera: CaptureDevice?) async {
        broadcastManager.setSelectedCamera(camera)
    }

    func setSelectedMicrophone(_ microphone: CaptureDevice?) async {
        do {
            try await updateCaptureConfiguration(selectedMicrophone: microphone)
        } catch {
            log.error("Failed to update stream configuration: \(error.localizedDescription)")
        }
    }

    func startBroadcast(
        primaryStreamKey: String,
        selectedMicrophone: CaptureDevice?,
        disconnected: @escaping @Sendable () async -> Void
    ) async throws {
        await stopBroadcast()

        do {
            try await updateCaptureConfiguration(selectedMicrophone: selectedMicrophone)
            let session = try await broadcastSessionBuilder.makeBroadcastSession(
                primaryStreamKey: primaryStreamKey
            )
            broadcastSession = session

            let stream = await session.stream()
            let frameRate = Float64(
                broadcastManager
                    .makeCaptureConfiguration(selectedMicrophone: selectedMicrophone)
                    .minimumFrameInterval.timescale
            )

            try await mediaMixerController.startBroadcast(
                stream: stream,
                frameRate: frameRate
            )
            try await session.connect { [weak self] in
                Task { @MainActor [weak self] in
                    await self?.stopBroadcast()
                    await disconnected()
                }
            }
        } catch {
            log.error("\(error.localizedDescription)")
            await stopBroadcast()
            throw error
        }
    }

    func stopBroadcast() async {
        guard broadcastSession != nil else {
            return
        }

        await mediaMixerController.stopBroadcast()

        do {
            try await broadcastSession?.close()
            broadcastSession = nil
        } catch {
            log.error("Error closing session: \(error.localizedDescription)")
            broadcastSession = nil
        }
    }

    private func updateCaptureConfiguration(selectedMicrophone: CaptureDevice?) async throws {
        let configuration = broadcastManager.makeCaptureConfiguration(
            selectedMicrophone: selectedMicrophone
        )

        do {
            try await mediaMixerController.updateCaptureConfiguration(
                configuration,
                using: captureSystem
            )
        } catch {
            throw error
        }
    }
}
