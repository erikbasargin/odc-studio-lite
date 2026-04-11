# AGENTS.md

This file provides guidance to AI agents working in this repository. It is the root intent node for the app, framework, generated artifacts, and planning docs.

## Repository Map

This repository is a Tuist-managed macOS app for broadcasting captured content:

- `Modules/App` - Main App target
- `Modules/AudioVideoKit` - Shared capture and discovery utilities
- `.agents/skills/` - Agent Skills
- `ci_scripts/` - Xcode Cloud CI scripts

## Global Guardrails

- Treat `Modules/` as the source of truth. Do not edit resources or generated files unless explicitly requested.
- Do not edit generated Tuist outputs or derived Info.plists unless explicitly requested.
- Keep changes narrowly scoped. Do not mix architecture migration, UI rewrites,
  and capture-pipeline refactors in one pass unless the user explicitly asks.
- The project is on Swift 6 with strict concurrency enabled in `Project.swift`, see `.agents/skills/swift-concurrency/SKILL.md`.
- Use SwiftUI for new UI components, see `.agents/skills/swiftui-pro/SKILL.md`.
- Use `mise run setup` to generate Xcode project if needed.
- Use Xcode MCP for builds and tests.
- Prefer editing docs in `Modules/App/Sources/ODCLite.docc` when the request is architectural or planning-oriented.

## Intent Layer Maintenance

When updating this file, keep it aligned with the actual repository instead of turning it into generic policy text.

- Update `Repository Map` when module paths, targets, or important entry points change.
- Update `Global Guardrails` when build tooling, concurrency rules, or source of truth boundaries change.
- Reflect architecture direction documented in `Modules/App/Sources/ODCLite.docc/TCAMigrationPlan.md`. Current intent: the app is in a staged migration from a `BroadcastManager`-centered design to The Composable Architecture.
- Until that migration is complete, prefer incremental seams: reducers and adapters around existing behavior rather than large rewrites of AVFoundation, ScreenCaptureKit, or RTMP internals.
- If new subdirectories gain their own `AGENTS.md`, keep this root file focused on cross-cutting repo guidance and push local workflow details down into the nearest intent node.
