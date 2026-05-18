# AGENTS.md

This file provides guidance to AI agents working in this repository. It is the root intent node for the app, framework, generated artifacts, and planning docs.

## Repository Map

This repository is a Tuist-managed macOS app for broadcasting captured content:

- `Modules/` - Modular app source organized by feature and framework layer
- `.agents/skills/` - Agent skills for swift-concurrency, swift-testing, and swiftui
- `ci_scripts/` - Xcode Cloud CI scripts

## Architecture

The app uses The Composable Architecture (TCA) for state management. Features are composed at the root reducer using scoped state and actions. Side effects are abstracted behind dependency clients. Heavy system work (capture pipeline, RTMP sessions) runs in dedicated actors.

Swift 6 strict concurrency is enforced project-wide. SwiftUI is used for all UI. Tests use the Swift Testing framework with TCA's `TestStore`.

Formatting is handled by `swift-format` (configured in `.swift-format`).

## Global Guardrails

- Treat `Modules/` as the source of truth. Do not edit generated Tuist outputs, derived Info.plists, or resources unless explicitly requested.
- Keep changes narrowly scoped. Do not mix architecture migration, UI rewrites, and capture-pipeline refactors in one pass unless the user explicitly asks.
- Prefer incremental seams: reducers and adapters around existing behavior rather than large rewrites of AVFoundation, ScreenCaptureKit, or RTMP internals.
- See `.agents/skills/swift-concurrency/SKILL.md` for concurrency guidance.
- See `.agents/skills/swiftui-pro/SKILL.md` for SwiftUI guidance.
- See `.agents/skills/swift-testing-expert/SKILL.md` for testing guidance.
- Prefer editing docs in `Modules/App/Sources/ODCLite.docc` when the request is architectural or planning-oriented.

## Development Workflow

The repository uses `mise` to pin Tuist and expose common workflows. Prefer `mise run <task>` instead of calling `tuist` directly. See `mise.toml` for the full task list.

- Some tasks (`setup`, `generate`, `g`, `edit`) may open Xcode. Prefer `mise run generateNoOpen` or `mise run gno` when regenerating while staying in the CLI lane.
- **If Xcode MCP is connected, prefer it for builds, tests, and IDE-driven tasks.** Fall back to `mise` only when Xcode MCP is not available.
- Use one workflow lane at a time: either Xcode MCP or `mise` commands. Do not interleave both in the same step.
- Do not run `xcodebuild` directly unless the user explicitly requests it.

## Intent Layer Maintenance

When updating this file, keep it aligned with the actual repository instead of turning it into generic policy text. Avoid referencing internal type names, specific modules, or version numbers that change more frequently than monthly.

- Update `Repository Map` when top-level directory structure changes.
- Update `Global Guardrails` when build tooling, concurrency rules, or source of truth boundaries change.
- If new subdirectories gain their own `AGENTS.md`, keep this root file focused on cross-cutting repo guidance and push local workflow details down into the nearest intent node.
