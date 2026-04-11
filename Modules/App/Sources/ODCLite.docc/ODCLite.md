# ``ODCLite``

ODC Lite captures a selected display, optionally mixes camera and microphone input, and publishes the result to Twitch.

## Overview

The app is built around a single `BroadcastManager` instance shared across the main app scene, menu bar extra, and settings window. At launch, ODC Lite:

- Registers the RTMP session factory.
- Configures `CaptureSystem` with the current screen and audio capture settings.
- Starts ScreenCaptureKit-based capture for the selected display.
- Activates the system sharing picker so the user can choose what to capture.
- Requests camera authorization for the optional camera source.

The menu bar extra is the primary control surface. From there, users can select a camera, select a microphone, enable a bandwidth test, open Settings, or start and stop a Twitch broadcast.

## Broadcast Flow

Broadcasting requires a non-empty Twitch primary stream key from Settings. When a broadcast starts, ODC Lite creates an RTMP session, applies H.264 video settings, attaches the mixed media output, and connects to Twitch. Stopping a broadcast shuts down the mixer and closes the active session.

## Shortcuts

ODC Lite provides two App Intents for microphone control:

- `StartCapturingMicrophone`
- `StopCapturingMicrophone`

These intents are surfaced as App Shortcuts so users can toggle microphone capture from the Shortcuts app or system automation features.
