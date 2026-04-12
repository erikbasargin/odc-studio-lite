# TCA Migration Plan

## Overview

This document describes a staged migration from the current
`BroadcastManager`-centered architecture to The Composable Architecture (TCA).
The goal is to introduce reducers, explicit state ownership, and testable
dependencies without destabilizing the existing capture and broadcast pipeline.

## Current Features

The current app behavior can be grouped into the following functional areas:

- Launch and bootstrap of screen capture, content picker activation, and camera
  authorization.
- Device selection for camera and microphone inputs.
- Twitch broadcast configuration through a primary stream key.
- RTMP session lifecycle management for start and stop broadcasting.
- Menu bar controls.
- App Shortcuts and App Intents for microphone capture control.

There are also partially implemented capabilities already present in the code:

- `excludeAppFromStream` exists in the domain logic but is not currently
  surfaced in the menu bar.
- `bandwidthTestEnabled` exists in state and UI, but the RTMP path does not yet
  implement bandwidth test behavior.
- Camera session and `AVCaptureVideoPreviewLayer` initialization exist to
  support system camera overlay via `SCContentSharingPicker`, but there is no
  dedicated in-app camera preview UI.

## Proposed TCA Feature Map

The current code naturally groups into the following TCA-oriented features.

### `AppFeature`

The root reducer that composes the app and coordinates shared state and
lifecycle.

Responsibilities:

- Compose child reducers.
- Hold shared top-level state.
- Own the main menu bar representation of the app.
- Own app bootstrap and launch coordination.
- Route lifecycle and integration actions.
- Inject long-lived dependencies.

### `BroadcastFeature`

Owns the core streaming domain that is currently concentrated in
`BroadcastManager`. Including UI to control Broadcast (start/stop) that
can be injected into menu bar.

Responsibilities:

- Own broadcast session state.
- Own runtime-mutable broadcast settings.
- Own available devices and selected camera and microphone state.
- Start and stop RTMP publishing.
- Apply capture configuration updates.
- Apply content filter updates.
- Manage mixer configuration.
- Observe connection status.
- Track authorization-related state.
- Surface broadcast-related errors.

This is the most important migration boundary.

### `SettingsFeature`

Owns settings UI and editable configuration.

Current responsibilities:

- Edit the Twitch primary stream key.
- Own mandatory and persisted app configuration.

### `ShortcutsFeature`

Owns the integration boundary for App Intents and App Shortcuts.

Responsibilities:

- Start microphone capture.
- Stop microphone capture.
- Route external actions into store-managed state transitions.

## State Ownership

A safe migration depends on clear state ownership:

- `BroadcastFeature` should own stream lifecycle, discovered devices, and
  selected inputs, plus runtime-mutable broadcast settings.
- `SettingsFeature` should own mandatory and persisted settings such as the
  Twitch primary stream key.
- `AppFeature` should compose feature state, coordinate lifecycle, and own the
  main menu bar presentation flow, including bootstrap.

## Dependency Boundaries

The current `BroadcastManager` mixes state, framework integrations, and side
effects. Before moving all of that into reducers, introduce only the service
boundaries that isolate the heavy framework behavior already concentrated in
`BroadcastManager`.

In this plan, a dependency boundary means a thin service or adapter used by a
reducer to perform imperative work without embedding AVFoundation,
ScreenCaptureKit, or RTMP details directly in reducer logic.

Recommended boundaries for this codebase:

- `CaptureSession`
  Wraps `CaptureSystem` start, stop, configuration, and content filter updates.
- `CameraAuthorizationService`
  Wraps camera authorization status checks and permission requests.
- `ContentSharingPickerService`
  Wraps `SCContentSharingPicker` configuration and activation.
- `BroadcastSession`
  Wraps RTMP session creation, mixer setup, connection lifecycle, and shutdown.
  Can register output from `CaptureSystem`.

This keeps the migration seams narrow and focused on the parts of the app that
are most side-effect heavy.

## Migration Plan

Use a staged migration. Start by wrapping the current structure with TCA, then
move ownership inward reducer by reducer.

### Phase 1: Introduce root and broadcast reducers - [Completed]

Goals:

- Add `AppFeature` as the root reducer.
- Add `BroadcastFeature` with actions and state that mirror current behavior.
- Move bootstrap orchestration into `AppFeature`.
- Keep `BroadcastManager` alive behind a dependency adapter.

Expected outcome:

- The app starts using a `Store` without immediately rewriting capture and RTMP
  internals.

### Phase 2: Extract Settings - [Completed]

Goals:

- Move the Twitch primary stream key UI into `SettingsFeature`.
- Define `SettingsFeature` as the owner of mandatory persisted settings.
- Route settings updates through TCA actions.

Expected outcome:

- The first user-facing flow becomes store-driven with low migration risk.

### Phase 3: Expand broadcast state ownership - [Completed]

Goals:

- Move camera and microphone discovery into `BroadcastFeature`.
- Move camera and microphone selection into `BroadcastFeature`.
- Replace direct environment mutation with reducer actions.

Expected outcome:

- Broadcast-related state becomes explicit and testable in one reducer.

### Phase 4: Move menu bar composition into `AppFeature` - [Completed]

Goals:

- Replace environment-driven bindings in the menu bar with `AppFeature` store
  state.
- Keep the view layer thin and declarative.

Expected outcome:

- The main app UI becomes store-driven from the root app reducer.

### Phase 5: Move launch orchestration into TCA - [Completed]

Goals:

- Move startup effects into `AppFeature`.
- Model bootstrap state explicitly at the app level.

Expected outcome:

- App startup becomes more predictable and easier to reason about without an
  extra reducer boundary.

### Phase 6: Integrate App Intents with the store - [Completed]

Goals:

- Route shortcut actions into store-managed behavior.
- Remove direct mutation paths that bypass reducer logic.

Expected outcome:

- External integrations participate in the same domain logic as the UI.

### Phase 7: Retire `BroadcastManager` incrementally

Goals:

- Move effect logic out of `BroadcastManager` into dependency services and
  reducer effects.
- Remove `BroadcastManager` only after reducer state ownership is complete.

Expected outcome:

- The app runs on TCA-native state management rather than an adapter layer.

## Recommended File Layout

One practical feature-oriented structure for the app module:

- `Sources/AppFeature/AppFeature.swift`
- `Tests/AppFeature/AppFeatureTests.swift`

- `Sources/BroadcastFeature/BroadcastFeature.swift`
- `Tests/BroadcastFeature/BroadcastFeatureTests.swift`

- `Sources/SettingsFeature/SettingsFeature.swift`
- `Tests/SettingsFeature/SettingsFeatureTests.swift`

- `Sources/ShortcutsFeature/ShortcutsFeature.swift`
- `Tests/ShortcutsFeature/ShortcutsFeatureTests.swift`


This keeps the code organized around behavior instead of framework types.

## Risks To Control

- Do not rewrite AVFoundation, ScreenCaptureKit, and RTMP code at the same time
  as introducing stores.
- Do not move bootstrap, broadcast, and device discovery behavior in a single
  step.
- Keep UI restructuring separate from low-level media pipeline changes.
- Preserve current async behavior behind dependency services first, then move
  state ownership into reducers.

## Success Criteria

The migration should be considered successful when:

- The menu bar and settings flows are store-driven.
- Mandatory settings are represented explicitly inside `SettingsFeature`.
- Broadcast lifecycle changes flow through reducer actions.
- App Intents stop mutating app state directly.
- `BroadcastManager` is reduced to an adapter and then removed.
- All features are covered with unit tests.
